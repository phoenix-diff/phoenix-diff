defmodule PhxDiff.Diffs do
  @moduledoc false

  alias PhxDiff.AppSpecification
  alias PhxDiff.ComparisonError
  alias PhxDiff.Diffs.AppRepo
  alias PhxDiff.Diffs.DiffEngine

  @type diff :: String.t()
  @type version :: Version.t()
  @type option :: String.t()

  @spec all_versions() :: [version]
  defdelegate all_versions, to: AppRepo

  @spec release_versions() :: [version]
  defdelegate release_versions, to: AppRepo

  @spec latest_version() :: version
  defdelegate latest_version, to: AppRepo

  @spec previous_release_version() :: version
  defdelegate previous_release_version, to: AppRepo

  @spec list_sample_apps_for_version(version) :: [AppSpecification.t()]
  defdelegate list_sample_apps_for_version(version), to: AppRepo

  @spec generate_sample_app(AppSpecification.t()) ::
          {:ok, String.t()} | {:error, :unknown_version}
  defdelegate generate_sample_app(app_spec), to: AppRepo

  @spec get_github_sample_app_base_url(AppSpecification.t()) :: String.t()
  defdelegate get_github_sample_app_base_url(app_spec), to: AppRepo

  @spec default_app_specification(version) :: AppSpecification.t()
  def default_app_specification(%Version{} = version) do
    if Version.match?(version, "~> 1.5.0-rc.0", allow_pre: true) do
      AppSpecification.new(version, ["--live"])
    else
      AppSpecification.new(version, [])
    end
  end

  @spec fetch_diff(AppSpecification.t(), AppSpecification.t()) ::
          {:ok, diff} | {:error, ComparisonError.t()}
  def fetch_diff(%AppSpecification{} = source_spec, %AppSpecification{} = target_spec) do
    metadata = %{source_spec: source_spec, target_spec: target_spec}

    :telemetry.span([:phx_diff, :diffs, :generate], metadata, fn ->
      case fetch_app_paths(source_spec, target_spec) do
        {:ok, source_path, target_path} ->
          diff = DiffEngine.compute_diff(source_path, target_path)
          {{:ok, diff}, metadata}

        {:error, %ComparisonError{} = error} ->
          {{:error, error}, Map.put(metadata, :error, error)}
      end
    end)
  end

  defp fetch_app_paths(source_spec, target_spec) do
    [{:source, source_spec}, {:target, target_spec}]
    |> Enum.reduce({%{}, []}, fn {field, spec}, {paths, errors} ->
      case AppRepo.fetch_app_path(spec) do
        {:ok, path} ->
          {Map.put(paths, field, path), errors}

        {:error, :invalid_version} ->
          {paths, Keyword.put(errors, field, :unknown_version)}
      end
    end)
    |> case do
      {%{source: source_path, target: target_path}, _} ->
        {:ok, source_path, target_path}

      {_, errors} ->
        {:error,
         ComparisonError.exception(source: source_spec, target: target_spec, errors: errors)}
    end
  end
end
