defmodule Mix.Tasks.PhxDiff.S3.SeedTest do
  use PhxDiff.MockedConfigCase, async: true

  @moduletag :tmp_dir

  import Mox

  alias ExAws.S3, as: S3Client
  alias Mix.Tasks.PhxDiff.S3.Seed

  @bucket "sample-apps"
  @prefix "sample-app"

  setup [{PhxDiff.SimulatorHelpers, :configure_for_s3_simulator}]

  setup %{tmp_dir: tmp_dir, aws_config: aws_config} do
    repo_path = Path.join(tmp_dir, "repo")

    PhxDiff.Config.Mock
    |> stub(:app_repo_path, fn -> repo_path end)
    |> stub(:app_repo_s3_bucket, fn -> @bucket end)
    |> stub(:app_repo_s3_prefix, fn -> @prefix end)
    |> stub(:app_repo_s3_region, fn -> "us-east-1" end)

    assert {:ok, _response} = S3Client.put_bucket(@bucket, "us-east-1") |> request(aws_config)

    [repo_path: repo_path]
  end

  test "uploads local sample apps to S3", %{aws_config: aws_config, repo_path: repo_path} do
    create_sample_app(repo_path, "1.7.1", "default")
    create_sample_app(repo_path, "1.7.1", "no-ecto")
    create_sample_app(repo_path, "1.8.0", "default")

    Seed.run([])

    assert_uploaded_app(aws_config, "sample-app/1.7.1/default.tgz")
    assert_uploaded_app(aws_config, "sample-app/1.7.1/no-ecto.tgz")
    assert_uploaded_app(aws_config, "sample-app/1.8.0/default.tgz")

    assert_received {:mix_shell, :info, ["Seeding 3 apps to s3://sample-apps/sample-app"]}
    assert_received {:mix_shell, :info, ["Uploaded: 3; skipped: 0; failed: 0"]}
  end

  test "skips existing archives by default", %{
    aws_config: aws_config,
    tmp_dir: tmp_dir,
    repo_path: repo_path
  } do
    create_sample_app(repo_path, "1.7.1", "default")

    Seed.run([])
    assert_successful_seed("1.7.1/default", "Uploaded", "Uploaded: 1; skipped: 0; failed: 0")

    File.write!(Path.join([repo_path, "1.7.1", "default", "mix.exs"]), "updated")
    Seed.run([])
    assert_successful_seed("1.7.1/default", "Skipped", "Uploaded: 0; skipped: 1; failed: 0")

    extracted_path = download_and_extract(aws_config, "sample-app/1.7.1/default.tgz", tmp_dir)
    assert File.read!(Path.join(extracted_path, "mix.exs")) == "1.7.1 default"
  end

  test "force overwrites existing archives", %{
    aws_config: aws_config,
    tmp_dir: tmp_dir,
    repo_path: repo_path
  } do
    create_sample_app(repo_path, "1.7.1", "default")

    Seed.run([])
    assert_successful_seed("1.7.1/default", "Uploaded", "Uploaded: 1; skipped: 0; failed: 0")

    File.write!(Path.join([repo_path, "1.7.1", "default", "mix.exs"]), "updated")
    Seed.run(["--force"])
    assert_successful_seed("1.7.1/default", "Uploaded", "Uploaded: 1; skipped: 0; failed: 0")

    extracted_path = download_and_extract(aws_config, "sample-app/1.7.1/default.tgz", tmp_dir)
    assert File.read!(Path.join(extracted_path, "mix.exs")) == "updated"
  end

  test "exits non-zero when uploads fail", %{s3_simulator: sim, repo_path: repo_path} do
    create_sample_app(repo_path, "1.7.1", "default")

    PhxDiff.S3Simulator.trigger_internal_server_errors(sim, operation: :put_object)

    assert {:shutdown, 1} = catch_exit(Seed.run([]))

    assert_failed_seed("1.7.1/default")
    assert_received {:mix_shell, :info, ["Uploaded: 0; skipped: 0; failed: 1"]}
  end

  test "exits non-zero when invalid access key is used", %{repo_path: repo_path} do
    stub(PhxDiff.Config.Mock, :s3_access_key_id, fn -> "wrong-key" end)

    create_sample_app(repo_path, "1.7.1", "default")

    assert {:shutdown, 1} = catch_exit(Seed.run([]))

    assert_failed_seed("1.7.1/default")
    assert_received {:mix_shell, :info, ["Uploaded: 0; skipped: 0; failed: 1"]}
  end

  test "exits non-zero when invalid secret access key is used", %{repo_path: repo_path} do
    stub(PhxDiff.Config.Mock, :s3_secret_access_key, fn -> "wrong-secret" end)

    create_sample_app(repo_path, "1.7.1", "default")

    assert {:shutdown, 1} = catch_exit(Seed.run([]))

    assert_failed_seed("1.7.1/default")
    assert_received {:mix_shell, :info, ["Uploaded: 0; skipped: 0; failed: 1"]}
  end

  defp assert_successful_seed(app_label, result, summary) do
    uploading_message = "[1/1] Uploading #{app_label}"
    result_message = "[1/1] #{result} #{app_label}"

    assert_received {:mix_shell, :info, ["Seeding 1 apps to s3://sample-apps/sample-app"]}
    assert_received {:mix_shell, :info, [^uploading_message]}
    assert_received {:mix_shell, :info, [^result_message]}
    assert_received {:mix_shell, :info, [^summary]}
  end

  defp assert_failed_seed(app_label) do
    uploading_message = "[1/1] Uploading #{app_label}"
    failed_message = "[1/1] Failed #{app_label}"

    assert_received {:mix_shell, :info, ["Seeding 1 apps to s3://sample-apps/sample-app"]}
    assert_received {:mix_shell, :info, [^uploading_message]}
    assert_received {:mix_shell, :error, [^failed_message]}
  end

  defp create_sample_app(repo_path, version, variant) do
    app_path = Path.join([repo_path, version, variant])
    File.mkdir_p!(app_path)
    File.write!(Path.join(app_path, "mix.exs"), "#{version} #{variant}")
  end

  defp download_and_extract(aws_config, key, tmp_dir) do
    assert {:ok, %{body: archive}} =
             S3Client.get_object(@bucket, key)
             |> request(aws_config)

    destination_path = Path.join(tmp_dir, "downloaded")
    File.mkdir_p!(destination_path)
    :erl_tar.extract({:binary, archive}, [:compressed, {:cwd, destination_path}])
    destination_path
  end

  defp assert_uploaded_app(aws_config, key) do
    assert {:ok, %{body: archive}} =
             S3Client.get_object(@bucket, key)
             |> request(aws_config)

    assert byte_size(archive) > 0
  end

  defp request(operation, aws_config), do: ExAws.request(operation, aws_config)
end
