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

  @spec fetch_default_app_specification!(version) :: AppSpecification.t() | no_return()
  def fetch_default_app_specification!(version) when is_binary(version) do
    case fetch_default_app_specification(version) do
      {:ok, app_specification} -> app_specification
      {:error, :invalid_version} -> raise Version.InvalidVersionError, version
    end
  end

  @spec fetch_default_app_specification(version) ::
          {:ok, AppSpecification.t()} | {:error, :invalid_version}
  def fetch_default_app_specification(version) when is_binary(version) do
    with {:ok, parsed_version} <- parse_version(version) do
      if Version.match?(parsed_version, ">= 1.5.0-rc.0") do
        {:ok, AppSpecification.new(parsed_version, ["--live"])}
      else
        {:ok, AppSpecification.new(parsed_version, [])}
      end
    end
  end

  defp parse_version(version_string) do
    case Version.parse(version_string) do
      {:ok, version} -> {:ok, version}
      :error -> {:error, :invalid_version}
    end
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
          {:ok, String.t()} | {:error, :unknown_version}
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
