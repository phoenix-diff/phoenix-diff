defmodule PhxDiff.Diffs.AppRepo.Store.S3 do
  @moduledoc false

  @behaviour PhxDiff.Diffs.AppRepo.Store

  alias ExAws.S3, as: S3Client
  alias PhxDiff.AppSpecification
  alias PhxDiff.Diffs.AppRepo.AppSpecPath
  alias PhxDiff.Diffs.AppRepo.Archive

  @archive_extension ".tgz"

  @spec app_key(AppSpecification.t()) :: String.t()
  def app_key(%AppSpecification{} = app_spec) do
    Path.join(normalized_prefix(), AppSpecPath.path(app_spec)) <> @archive_extension
  end

  @spec put_archive(AppSpecification.t(), binary()) :: :ok | {:error, :storage_unavailable}
  def put_archive(%AppSpecification{} = app_spec, archive) when is_binary(archive) do
    case request(S3Client.put_object(bucket(), app_key(app_spec), archive)) do
      {:ok, _response} -> :ok
      _ -> {:error, :storage_unavailable}
    end
  end

  @spec archive_exists?(AppSpecification.t()) :: {:ok, boolean()} | {:error, :storage_unavailable}
  def archive_exists?(%AppSpecification{} = app_spec) do
    case request(S3Client.head_object(bucket(), app_key(app_spec))) do
      {:ok, %{status_code: 200}} -> {:ok, true}
      {:error, {:http_error, 404, _response}} -> {:ok, false}
      _ -> {:error, :storage_unavailable}
    end
  end

  @impl true
  def list_app_specs do
    prefix = normalized_prefix()

    case request(S3Client.list_objects_v2(bucket(), prefix: prefix)) do
      {:ok, response} ->
        specs =
          response
          |> object_keys()
          |> Enum.flat_map(&key_to_app_spec(&1, prefix))

        {:ok, specs}

      _ ->
        {:error, :storage_unavailable}
    end
  end

  @impl true
  def list_app_specs_for_version(%Version{} = version) do
    prefix = Path.join(normalized_prefix(), to_string(version)) <> "/"

    case request(S3Client.list_objects_v2(bucket(), prefix: prefix)) do
      {:ok, response} ->
        specs =
          response
          |> object_keys()
          |> Enum.flat_map(&key_to_app_spec(&1, normalized_prefix()))

        {:ok, specs}

      _ ->
        {:error, :storage_unavailable}
    end
  end

  @impl true
  def fetch_app_path(%AppSpecification{} = app_spec) do
    cache_path = app_path(app_spec)

    if File.dir?(cache_path) do
      {:ok, cache_path}
    else
      app_spec
      |> fetch_remote_app()
      |> materialize_app(cache_path)
    end
  end

  @impl true
  def store_generated_app(%AppSpecification{} = app_spec, source_path) do
    with {:ok, archive} <- Archive.create(source_path),
         :ok <- put_archive(app_spec, archive),
         :ok <- Archive.extract(archive, app_path(app_spec)) do
      {:ok, app_path(app_spec)}
    else
      _ -> {:error, :storage_unavailable}
    end
  end

  defp fetch_remote_app(app_spec) do
    case request(S3Client.get_object(bucket(), app_key(app_spec))) do
      {:ok, %{body: archive}} -> {:ok, archive}
      {:error, reason} -> {:error, fetch_error(reason)}
    end
  end

  defp materialize_app({:error, reason}, _cache_path), do: {:error, reason}

  defp materialize_app({:ok, archive}, cache_path) do
    temp_path = "#{cache_path}.tmp-#{System.unique_integer([:positive])}"

    with :ok <- File.mkdir_p(Path.dirname(cache_path)),
         :ok <- Archive.extract(archive, temp_path),
         :ok <- move_cache_into_place(temp_path, cache_path) do
      {:ok, cache_path}
    else
      _ ->
        File.rm_rf(temp_path)
        {:error, :storage_unavailable}
    end
  end

  defp move_cache_into_place(temp_path, cache_path) do
    case File.rename(temp_path, cache_path) do
      :ok ->
        :ok

      {:error, :eexist} ->
        File.rm_rf(temp_path)
        :ok

      error ->
        error
    end
  end

  defp key_to_app_spec(key, prefix) do
    with true <- String.starts_with?(key, prefix),
         true <- String.ends_with?(key, @archive_extension),
         relative_key <- String.trim_leading(key, prefix),
         relative_key <- String.trim_leading(relative_key, "/"),
         relative_path <- String.trim_trailing(relative_key, @archive_extension),
         [_, _] <- Path.split(relative_path) do
      [AppSpecPath.from_path(relative_path)]
    else
      _ -> []
    end
  rescue
    _ -> []
  end

  defp object_keys(%{body: %{contents: contents}}) when is_list(contents) do
    Enum.map(contents, &object_key/1)
  end

  defp object_keys(%{body: contents}) when is_list(contents) do
    Enum.map(contents, &object_key/1)
  end

  defp object_keys(_response), do: []

  defp object_key(object) when is_map(object) do
    object[:key] || object["key"] || object[:Key] || object["Key"]
  end

  defp app_path(app_spec) do
    PhxDiff.Config.app_repo_cache_path()
    |> Path.join(AppSpecPath.path(app_spec))
  end

  defp normalized_prefix do
    PhxDiff.Config.app_repo_s3_prefix()
    |> String.trim("/")
  end

  defp bucket, do: PhxDiff.Config.app_repo_s3_bucket()

  defp request(operation), do: ExAws.request(operation, aws_config())

  defp aws_config do
    endpoint = URI.parse(PhxDiff.Config.s3_base_url())

    [
      access_key_id: System.get_env("AWS_ACCESS_KEY_ID", "test"),
      secret_access_key: System.get_env("AWS_SECRET_ACCESS_KEY", "test"),
      region: PhxDiff.Config.app_repo_s3_region(),
      scheme: "#{endpoint.scheme}://",
      host: endpoint.host,
      port: endpoint.port,
      normalize_path: false,
      retries: [
        max_attempts: 1,
        max_attempts_client: 1
      ]
    ]
  end

  defp fetch_error({:http_error, 404, _response}), do: :invalid_version
  defp fetch_error(_reason), do: :storage_unavailable
end
