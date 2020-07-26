defmodule PhxDiff.Diffs do
  @moduledoc """
  Primary API for retrieving diffs
  """

  alias PhxDiff.Diffs.AppRepo
  alias PhxDiff.Diffs.AppSpecification
  alias PhxDiff.Diffs.Config
  alias PhxDiff.Diffs.DiffEngine

  @type diff :: String.t()
  @type version :: String.t()
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

  @spec get_diff(AppSpecification.t(), AppSpecification.t(), [config_opt]) ::
          {:ok, diff} | {:error, :invalid_versions}
  def get_diff(%AppSpecification{} = source_spec, %AppSpecification{} = target_spec, opts \\ [])
      when is_list(opts) do
    config = get_config(opts)

    with {:ok, source_path} <- AppRepo.fetch_app_path(config, source_spec),
         {:ok, target_path} <- AppRepo.fetch_app_path(config, target_spec) do
      diff = DiffEngine.compute_diff(source_path, target_path)
      {:ok, diff}
    else
      {:error, :invalid_version} -> {:error, :invalid_versions}
    end
  end

  @spec generate_sample_app(AppSpecification.t(), [config_opt]) ::
          {:ok, String.t()} | {:error, :invalid_version}
  def generate_sample_app(%AppSpecification{} = app_spec, opts \\ []) when is_list(opts) do
    config = get_config(opts)

    AppRepo.generate_sample_app(config, app_spec)
  end

  defp get_config(opts) when is_list(opts) do
    Keyword.get_lazy(opts, :config, &default_config/0)
  end

  defp default_config do
    %Config{
      app_repo_path: "data/sample-app",
      app_generator_workspace_path: "tmp"
    }
  end
end
