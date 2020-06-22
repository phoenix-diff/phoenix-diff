defmodule PhxDiff.Diffs.AppRepo do
  @moduledoc false

  alias PhxDiff.Diffs.AppSpecification

  @type version :: Phoenix.Diffs.version()

  @sample_app_path "data/sample-app"

  @spec all_versions() :: [version]
  def all_versions do
    app_specifications_for_pre_generated_apps()
    |> MapSet.new(& &1.phoenix_version)
    |> MapSet.to_list()
    |> Enum.sort_by(&Version.parse!/1, &(Version.compare(&1, &2) == :lt))
  end

  @spec release_versions() :: [version]
  def release_versions, do: all_versions() |> Enum.reject(&pre_release?/1)

  defp pre_release?(version), do: !Enum.empty?(Version.parse!(version).pre)

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

  @spec fetch_app_path(AppSpecification.t()) :: {:ok, String.t()} | {:error, :invalid_version}
  def fetch_app_path(%AppSpecification{} = app_specification) do
    if app_generated_for_specification?(app_specification) do
      {:ok, app_path(app_specification)}
    else
      {:error, :invalid_version}
    end
  end

  defp app_generated_for_specification?(%AppSpecification{} = app_specification) do
    app_specification in app_specifications_for_pre_generated_apps()
  end

  defp app_path(%AppSpecification{phoenix_version: version}), do: "#{@sample_app_path}/#{version}"

  defp app_specifications_for_pre_generated_apps do
    @sample_app_path
    |> File.ls!()
    |> Enum.map(&AppSpecification.new/1)
  end
end
