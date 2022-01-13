defmodule PhxDiff.Diffs do
  @moduledoc """
  Primary API for retrieving diffs
  """

  alias PhxDiff.Diffs.AppRepo
  alias PhxDiff.Diffs.AppSpecification
  alias PhxDiff.Diffs.ComparisonError
  alias PhxDiff.Diffs.Config
  alias PhxDiff.Diffs.DiffEngine

  @type diff :: String.t()
  @type version :: Version.t()
  @type option :: String.t()

  @type config_opt :: {:config, Config.t()}

  @spec all_versions([config_opt]) :: [version]
  def all_versions(opts \\ []) when is_list(opts) do
    opts
    |> get_config()
    |> AppRepo.all_versions()
  end

  @spec release_versions([config_opt]) :: [version]
  def release_versions(opts \\ []) when is_list(opts) do
    opts
    |> get_config()
    |> AppRepo.release_versions()
  end

  @spec latest_version([config_opt]) :: version
  def latest_version(opts \\ []) when is_list(opts) do
    opts
    |> get_config()
    |> AppRepo.latest_version()
  end

  @spec previous_release_version([config_opt]) :: version
  def previous_release_version(opts \\ []) when is_list(opts) do
    opts
    |> get_config()
    |> AppRepo.previous_release_version()
  end

  @spec default_app_specification(version) :: AppSpecification.t()
  def default_app_specification(%Version{} = version) do
    if Version.match?(version, ">= 1.5.0-rc.0") do
      AppSpecification.new(version, ["--live"])
    else
      AppSpecification.new(version, [])
    end
  end

  @spec get_diff(AppSpecification.t(), AppSpecification.t(), [config_opt]) ::
          {:ok, diff} | {:error, ComparisonError.t()}
  def get_diff(%AppSpecification{} = source_spec, %AppSpecification{} = target_spec, opts \\ [])
      when is_list(opts) do
    config = get_config(opts)
    metadata = %{source_spec: source_spec, target_spec: target_spec}

    :telemetry.span([:phx_diff, :diffs, :generate], metadata, fn ->
      case fetch_app_paths(config, source_spec, target_spec) do
        {:ok, source_path, target_path} ->
          diff = DiffEngine.compute_diff(source_path, target_path)
          {{:ok, diff}, metadata}

        {:error, %ComparisonError{} = error} ->
          {{:error, error}, Map.put(metadata, :error, error)}
      end
    end)
  end

  @spec generate_sample_app(AppSpecification.t(), [config_opt]) ::
          {:ok, String.t()} | {:error, :unknown_version}
  def generate_sample_app(%AppSpecification{} = app_spec, opts \\ []) when is_list(opts) do
    config = get_config(opts)

    AppRepo.generate_sample_app(config, app_spec)
  end

  defp fetch_app_paths(config, source_spec, target_spec) do
    [{:source, source_spec}, {:target, target_spec}]
    |> Enum.reduce({%{}, []}, fn {field, spec}, {paths, errors} ->
      case AppRepo.fetch_app_path(config, spec) do
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

  defp get_config(opts) when is_list(opts) do
    Keyword.get_lazy(opts, :config, &default_config/0)
  end

  defp default_config do
    %Config{
      app_repo_path: Application.app_dir(:phx_diff, "priv/data/sample-app"),
      app_generator_workspace_path: "tmp"
    }
  end
end
