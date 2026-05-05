defmodule PhxDiff.Diffs.AppRepo.Store.S3 do
  @moduledoc false

  @behaviour PhxDiff.Diffs.AppRepo.Store.Adapter

  alias ExAws.S3, as: ExAwsS3
  alias PhxDiff.AppSpecification
  alias PhxDiff.AppStorageInfo
  alias PhxDiff.Diffs.AppRepo.AppSpecPath

  @impl true
  def list_app_specs do
    specs =
      PhxDiff.Config.app_repo_s3_store_cache_path()
      |> Path.join("*/*")
      |> Path.wildcard()
      |> Enum.map(&path_to_app_spec/1)

    {:ok, specs}
  end

  @impl true
  def list_app_specs_for_version(%Version{} = version) do
    specs =
      PhxDiff.Config.app_repo_s3_store_cache_path()
      |> Path.join("#{version}/*")
      |> Path.wildcard()
      |> Enum.map(&path_to_app_spec/1)

    {:ok, specs}
  end

  @impl true
  def fetch_app_path(%AppSpecification{} = app_spec) do
    with {:ok, app_specs} <- list_app_specs() do
      if app_spec in app_specs do
        {:ok, app_path(app_spec)}
      else
        {:error, :invalid_version}
      end
    end
  end

  @impl true
  def store_generated_app(%AppSpecification{} = app_spec, source_path) do
    destination_path = app_path(app_spec)

    File.rm_rf(destination_path)
    File.mkdir_p!(destination_path)

    File.rename!(source_path, destination_path)
    upload_archive!(app_spec, destination_path)

    {:ok, AppStorageInfo.new(destination_path, nil)}
  end

  defp upload_archive!(app_spec, app_path) do
    archive_path = archive_path(app_spec)

    try do
      create_archive!(archive_path, app_path)

      PhxDiff.Config.app_repo_s3_store_bucket()
      |> ExAwsS3.put_object(archive_key(app_spec), File.read!(archive_path), content_type: "application/gzip")
      |> ExAws.request!(aws_config())
    after
      File.rm(archive_path)
    end
  end

  defp create_archive!(archive_path, app_path) do
    app_parent_path = Path.dirname(app_path)
    app_dir_name = Path.basename(app_path)

    File.mkdir_p!(Path.dirname(archive_path))

    {_output, 0} = System.cmd("tar", ["-czf", archive_path, "-C", app_parent_path, app_dir_name])
  end

  defp archive_path(app_spec) do
    Path.join(System.tmp_dir!(), "#{System.unique_integer([:positive])}-#{archive_key(app_spec)}")
  end

  defp archive_key(app_spec) do
    AppSpecPath.path(app_spec) <> ".tar.gz"
  end

  defp aws_config do
    uri = URI.parse(PhxDiff.Config.s3_base_url())

    [
      access_key_id: PhxDiff.Config.s3_access_key_id(),
      secret_access_key: PhxDiff.Config.s3_secret_access_key(),
      region: PhxDiff.Config.s3_region(),
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

  defp app_path(app_spec) do
    Path.join(PhxDiff.Config.app_repo_s3_store_cache_path(), AppSpecPath.path(app_spec))
  end

  defp path_to_app_spec(path) do
    path
    |> Path.relative_to(PhxDiff.Config.app_repo_s3_store_cache_path())
    |> AppSpecPath.from_path()
  end
end
