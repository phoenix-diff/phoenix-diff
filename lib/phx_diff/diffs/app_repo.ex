defmodule PhxDiff.Diffs.AppRepo do
  @moduledoc false

  alias PhxDiff.AppSpecification
  alias PhxDiff.Diffs

  alias PhxDiff.Diffs.AppRepo.AppGenerator

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
    if app_generated_for_specification?(app_specification) do
      {:ok, app_path(app_specification)}
    else
      {:error, :invalid_version}
    end
  end

  @spec generate_sample_app(AppSpecification.t()) ::
          {:ok, String.t()} | {:error, :unknown_version}
  def generate_sample_app(%AppSpecification{} = app_spec) do
    with {:ok, app_dir} <- AppGenerator.generate(app_spec) do
      store_generated_app(app_spec, app_dir)
    end
  end

  defp store_generated_app(app_spec, source_path) do
    destination_path = app_path(app_spec)

    File.rm_rf(destination_path)
    File.mkdir_p!(destination_path)

    File.rename!(source_path, destination_path)

    {:ok, destination_path}
  end

  defp app_generated_for_specification?(app_spec) do
    app_spec in app_specifications_for_pre_generated_apps()
  end

  defp app_path(app_spec) do
    %AppSpecification{phoenix_version: version} = app_spec

    PhxDiff.Config.app_repo_path()
    |> Path.join(to_string(version))
  end

  defp app_specifications_for_pre_generated_apps do
    PhxDiff.Config.app_repo_path()
    |> File.ls()
    |> case do
      {:ok, files} ->
        files
        |> Enum.map(&Version.parse!/1)
        |> Enum.map(&Diffs.default_app_specification/1)

      {:error, _reason} ->
        []
    end
  end
end
