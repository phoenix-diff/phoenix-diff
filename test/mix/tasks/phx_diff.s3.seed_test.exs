defmodule Mix.Tasks.PhxDiff.S3.SeedTest do
  use PhxDiff.MockedConfigCase, async: true

  @moduletag :tmp_dir

  import Mox

  alias ExAws.S3, as: S3Client
  alias Mix.Tasks.PhxDiff.S3.Seed
  alias PhxDiff.Diffs.AppRepo.Archive

  @bucket "sample-apps"
  @prefix "sample-app"

  setup [{PhxDiff.SimulatorHelpers, :configure_for_s3_simulator}]

  setup %{tmp_dir: tmp_dir} do
    endpoint = PhxDiff.Config.s3_base_url()
    aws_config = aws_config(endpoint)
    repo_path = Path.join(tmp_dir, "repo")

    PhxDiff.Config.Mock
    |> stub(:app_repo_path, fn -> repo_path end)
    |> stub(:app_repo_s3_bucket, fn -> @bucket end)
    |> stub(:app_repo_s3_prefix, fn -> @prefix end)
    |> stub(:app_repo_s3_region, fn -> "us-east-1" end)

    assert {:ok, _response} = S3Client.put_bucket(@bucket, "us-east-1") |> request(aws_config)

    create_sample_app(repo_path, "1.7.1", "default")
    create_sample_app(repo_path, "1.7.1", "no-ecto")
    create_sample_app(repo_path, "1.8.0", "default")

    [aws_config: aws_config, repo_path: repo_path]
  end

  test "uploads local sample apps to S3", %{aws_config: aws_config} do
    Seed.run([])

    assert_uploaded_app(aws_config, "sample-app/1.7.1/default.tgz")
    assert_uploaded_app(aws_config, "sample-app/1.7.1/no-ecto.tgz")
    assert_uploaded_app(aws_config, "sample-app/1.8.0/default.tgz")

    assert_received {:mix_shell, :info, ["Uploaded: 3; skipped: 0; failed: 0"]}
  end

  test "skips existing archives by default", %{} do
    Seed.run([])
    Seed.run([])

    assert_received {:mix_shell, :info, ["Uploaded: 0; skipped: 3; failed: 0"]}
  end

  test "force overwrites existing archives", %{aws_config: aws_config, repo_path: repo_path} do
    Seed.run([])
    File.write!(Path.join([repo_path, "1.7.1", "default", "mix.exs"]), "updated")

    Seed.run(["--force", "--version", "1.7.1", "--variant", "default"])

    assert {:ok, %{body: archive}} =
             S3Client.get_object(@bucket, "sample-app/1.7.1/default.tgz")
             |> request(aws_config)

    destination_path = Path.join(repo_path, "downloaded")
    assert :ok = Archive.extract(archive, destination_path)
    assert File.read!(Path.join(destination_path, "mix.exs")) == "updated"

    assert_received {:mix_shell, :info, ["Uploaded: 1; skipped: 0; failed: 0"]}
  end

  test "version and variant filters limit uploaded apps", %{aws_config: aws_config} do
    Seed.run(["--version", "1.7.1", "--variant", "no-ecto"])

    assert {:error, _reason} =
             S3Client.get_object(@bucket, "sample-app/1.7.1/default.tgz")
             |> request(aws_config)

    assert_uploaded_app(aws_config, "sample-app/1.7.1/no-ecto.tgz")
    assert_received {:mix_shell, :info, ["Uploaded: 1; skipped: 0; failed: 0"]}
  end

  test "exits non-zero when uploads fail", %{s3_simulator: sim} do
    PhxDiff.S3Simulator.trigger_internal_server_errors(sim, operation: :put_object)

    assert {:shutdown, 1} = catch_exit(Seed.run(["--version", "1.7.1", "--variant", "default"]))

    assert_received {:mix_shell, :error, ["Failed 1.7.1/default"]}
    assert_received {:mix_shell, :info, ["Uploaded: 0; skipped: 0; failed: 1"]}
  end

  defp create_sample_app(repo_path, version, variant) do
    app_path = Path.join([repo_path, version, variant])
    File.mkdir_p!(app_path)
    File.write!(Path.join(app_path, "mix.exs"), "#{version} #{variant}")
  end

  defp assert_uploaded_app(aws_config, key) do
    assert {:ok, %{body: archive}} =
             S3Client.get_object(@bucket, key)
             |> request(aws_config)

    assert byte_size(archive) > 0
  end

  defp request(operation, aws_config), do: ExAws.request(operation, aws_config)

  defp aws_config(endpoint) do
    uri = URI.parse(endpoint)

    [
      access_key_id: "test",
      secret_access_key: "test",
      region: "us-east-1",
      scheme: "#{uri.scheme}://",
      host: uri.host,
      port: uri.port,
      normalize_path: false,
      retries: [
        max_attempts: 1,
        max_attempts_client: 1
      ]
    ]
  end
end
