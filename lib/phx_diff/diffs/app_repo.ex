defmodule PhxDiff.Diffs.AppRepo do
  @moduledoc false

  @type version :: Phoenix.Diffs.version()

  @sample_app_path "data/sample-app"

  @spec all_versions() :: [version]
  def all_versions do
    @sample_app_path
    |> File.ls!()
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

  @spec fetch_app_path(version) :: {:ok, String.t()} | {:error, :invalid_version}
  def fetch_app_path(version) do
    if version in all_versions() do
      {:ok, "#{@sample_app_path}/#{version}"}
    else
      {:error, :invalid_version}
    end
  end
end
