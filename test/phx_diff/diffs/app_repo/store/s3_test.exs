defmodule PhxDiff.Diffs.AppRepo.Store.S3Test do
  use PhxDiff.MockedConfigCase, async: true

  import Mox
  import PhxDiff.TestSupport.Sigils

  alias ExAws.S3, as: S3Client
  alias PhxDiff.AppSpecification
  alias PhxDiff.Diffs.AppRepo.Archive
  alias PhxDiff.Diffs.AppRepo.Store.S3
  alias PhxDiff.S3Simulator

  @bucket "sample-apps"
  @prefix "sample-app"
  @app_spec %AppSpecification{phoenix_version: ~V[1.7.1], phx_new_arguments: []}

  setup [{PhxDiff.SimulatorHelpers, :configure_for_s3_simulator}]

  setup %{tmp_dir: tmp_dir} do
    endpoint = PhxDiff.Config.s3_base_url()
    aws_config = aws_config(endpoint)

    PhxDiff.Config.Mock
    |> stub(:app_repo_cache_path, fn -> Path.join(tmp_dir, "cache") end)
    |> stub(:app_repo_s3_bucket, fn -> @bucket end)
    |> stub(:app_repo_s3_prefix, fn -> @prefix end)
    |> stub(:app_repo_s3_region, fn -> "us-east-1" end)

    assert {:ok, _response} = S3Client.put_bucket(@bucket, "us-east-1") |> request(aws_config)

    [aws_config: aws_config]
  end

  describe "list_app_specs/0" do
    @tag :tmp_dir
    test "lists app specs from S3 archive keys and ignores malformed keys", %{
      aws_config: aws_config
    } do
      assert {:ok, _response} =
               S3Client.put_object(@bucket, "#{@prefix}/1.7.1/default.tgz", "archive")
               |> request(aws_config)

      assert {:ok, _response} =
               S3Client.put_object(@bucket, "#{@prefix}/1.7.1/no-ecto.tgz", "archive")
               |> request(aws_config)

      assert {:ok, _response} =
               S3Client.put_object(@bucket, "#{@prefix}/1.7.1/not-a-known-option.tgz", "archive")
               |> request(aws_config)

      assert {:ok, _response} =
               S3Client.put_object(@bucket, "#{@prefix}/1.7.1/default.txt", "archive")
               |> request(aws_config)

      assert {:ok, app_specs} = S3.list_app_specs()

      assert app_specs == [
               %AppSpecification{phoenix_version: ~V[1.7.1], phx_new_arguments: []},
               %AppSpecification{phoenix_version: ~V[1.7.1], phx_new_arguments: ["--no-ecto"]}
             ]
    end

    @tag :tmp_dir
    test "returns storage_unavailable when S3 listing fails", %{s3_simulator: sim} do
      S3Simulator.trigger_internal_server_errors(sim, operation: :list_objects)

      assert {:error, :storage_unavailable} = S3.list_app_specs()
    end
  end

  describe "list_app_specs_for_version/1" do
    @tag :tmp_dir
    test "lists only app specs for the requested version", %{aws_config: aws_config} do
      assert {:ok, _response} =
               S3Client.put_object(@bucket, "#{@prefix}/1.7.1/default.tgz", "archive")
               |> request(aws_config)

      assert {:ok, _response} =
               S3Client.put_object(@bucket, "#{@prefix}/1.7.2/default.tgz", "archive")
               |> request(aws_config)

      assert {:ok, app_specs} = S3.list_app_specs_for_version(~V[1.7.1])

      assert app_specs == [
               %AppSpecification{phoenix_version: ~V[1.7.1], phx_new_arguments: []}
             ]
    end
  end

  describe "fetch_app_path/1" do
    @tag :tmp_dir
    test "returns the cached app path without downloading", %{tmp_dir: tmp_dir, s3_simulator: sim} do
      cache_path = Path.join([tmp_dir, "cache", "1.7.1", "default"])
      File.mkdir_p!(cache_path)
      File.write!(Path.join(cache_path, "mix.exs"), "cached")

      S3Simulator.trigger_internal_server_errors(sim, operation: :get_object)

      assert {:ok, ^cache_path} = S3.fetch_app_path(@app_spec)
    end

    @tag :tmp_dir
    test "downloads and extracts an app archive on cache miss", %{
      tmp_dir: tmp_dir,
      aws_config: aws_config
    } do
      source_path = sample_app_path(tmp_dir)
      {:ok, archive} = Archive.create(source_path)

      assert {:ok, _response} =
               S3Client.put_object(@bucket, "#{@prefix}/1.7.1/default.tgz", archive)
               |> request(aws_config)

      assert {:ok, cache_path} = S3.fetch_app_path(@app_spec)
      assert cache_path == Path.join([tmp_dir, "cache", "1.7.1", "default"])

      assert File.read!(Path.join(cache_path, "mix.exs")) ==
               "defmodule Sample.MixProject do\nend\n"

      assert File.read!(Path.join(cache_path, ".formatter.exs")) == "[]"
    end

    @tag :tmp_dir
    test "returns invalid_version when the archive is missing" do
      assert {:error, :invalid_version} = S3.fetch_app_path(@app_spec)
    end

    @tag :tmp_dir
    test "returns storage_unavailable when downloading fails", %{s3_simulator: sim} do
      S3Simulator.trigger_internal_server_errors(sim, operation: :get_object)

      assert {:error, :storage_unavailable} = S3.fetch_app_path(@app_spec)
    end
  end

  describe "store_generated_app/2" do
    @tag :tmp_dir
    test "uploads an app archive and stores it in the local cache", %{
      tmp_dir: tmp_dir,
      aws_config: aws_config
    } do
      source_path = sample_app_path(tmp_dir)

      assert {:ok, cache_path} = S3.store_generated_app(@app_spec, source_path)

      assert File.read!(Path.join(cache_path, "mix.exs")) ==
               "defmodule Sample.MixProject do\nend\n"

      assert {:ok, %{body: archive}} =
               S3Client.get_object(@bucket, "#{@prefix}/1.7.1/default.tgz")
               |> request(aws_config)

      destination_path = Path.join(tmp_dir, "uploaded")
      assert :ok = Archive.extract(archive, destination_path)

      assert File.read!(Path.join(destination_path, "mix.exs")) ==
               "defmodule Sample.MixProject do\nend\n"
    end
  end

  defp sample_app_path(tmp_dir) do
    source_path = Path.join(tmp_dir, "source")
    File.mkdir_p!(source_path)
    File.write!(Path.join(source_path, "mix.exs"), "defmodule Sample.MixProject do\nend\n")
    File.write!(Path.join(source_path, ".formatter.exs"), "[]")
    source_path
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
