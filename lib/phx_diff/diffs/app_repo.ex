defmodule PhxDiff.Diffs.AppRepo do
  @moduledoc false

  alias PhxDiff.AppSpecification
  alias PhxDiff.Diffs.AppRepo.AppGenerator
  alias PhxDiff.Diffs.AppRepo.AppSpecPath

  @type version :: PhxDiff.Diffs.version()

  @spec all_versions() :: [version]
  def all_versions do
    app_specifications_for_pre_generated_apps()
    |> MapSet.new(& &1.phoenix_version)
    |> MapSet.to_list()
    |> Enum.sort(&(Version.compare(&1, &2) == :lt))
  end

  @spec release_versions() :: [version]
  def release_versions, do: all_versions() |> Enum.reject(&pre_release?/1)

  defp pre_release?(version), do: !Enum.empty?(version.pre)

  @spec latest_version() :: version
  def latest_version, do: all_versions() |> List.last()

  @spec previous_release_version() :: version
  def previous_release_version do
    releases = release_versions()
    latest_release = releases |> List.last()

    if latest_version() == latest_release do
      releases |> Enum.at(-2)
    else
      latest_release
    end
  end

  @spec fetch_app_path(AppSpecification.t()) ::
          {:ok, String.t()} | {:error, :invalid_version}
  def fetch_app_path(%AppSpecification{} = app_specification) do
    store().fetch_app_path(app_specification)
  end

  @spec list_sample_apps_for_version(Version.t()) :: [AppSpecification.t()]
  def list_sample_apps_for_version(%Version{} = version) do
    case store().list_app_specs_for_version(version) do
      {:ok, app_specs} -> app_specs
      {:error, :storage_unavailable} -> []
    end
  end

  @spec generate_sample_app(AppSpecification.t()) ::
          {:ok, String.t()} | {:error, :unknown_version}
  def generate_sample_app(%AppSpecification{} = app_spec) do
    with {:ok, app_dir} <- AppGenerator.generate(app_spec) do
      store().store_generated_app(app_spec, app_dir)
    end
  end

  @spec list_app_files(AppSpecification.t()) ::
          {:ok, [String.t()]} | {:error, :invalid_version}
  def list_app_files(%AppSpecification{} = app_spec) do
    with {:ok, root} <- fetch_app_path(app_spec) do
      files =
        root
        |> Path.join("**")
        |> Path.wildcard(match_dot: true)
        |> Enum.filter(&File.regular?/1)
        |> Enum.map(&Path.relative_to(&1, root))
        |> Enum.sort()

      {:ok, files}
    end
  end

  @spec read_app_file(AppSpecification.t(), String.t()) ::
          {:ok, String.t()} | {:error, :invalid_version | :not_found | :binary_file}
  def read_app_file(%AppSpecification{} = app_spec, relative_path) do
    with {:ok, content} <- read_file_bytes(app_spec, relative_path) do
      if String.contains?(content, <<0>>) do
        {:error, :binary_file}
      else
        {:ok, content}
      end
    end
  end

  @spec read_raw_app_file(AppSpecification.t(), String.t()) ::
          {:ok, binary()} | {:error, :invalid_version | :not_found}
  def read_raw_app_file(%AppSpecification{} = app_spec, relative_path) do
    read_file_bytes(app_spec, relative_path)
  end

  defp read_file_bytes(app_spec, relative_path) do
    with :ok <- validate_path(relative_path),
         {:ok, root} <- fetch_app_path(app_spec),
         full_path <- Path.expand(relative_path, root),
         true <- String.starts_with?(full_path, Path.expand(root)),
         true <- File.regular?(full_path),
         {:ok, content} <- File.read(full_path) do
      {:ok, content}
    else
      {:error, _} = error -> error
      _ -> {:error, :not_found}
    end
  end

  defp validate_path(path) do
    segments = Path.split(path)

    cond do
      segments == [] -> {:error, :not_found}
      Enum.any?(segments, &(&1 in [".", ".."])) -> {:error, :not_found}
      true -> :ok
    end
  end

  @spec get_github_sample_app_base_url(AppSpecification.t()) :: String.t()
  def get_github_sample_app_base_url(%AppSpecification{} = app_spec) do
    PhxDiff.Config.github_sample_app_base_url()
    |> Path.join(AppSpecPath.path(app_spec))
  end

  defp app_specifications_for_pre_generated_apps do
    case store().list_app_specs() do
      {:ok, app_specs} -> app_specs
      {:error, :storage_unavailable} -> []
    end
  end

  defp store, do: PhxDiff.Config.app_repo_store()
end
