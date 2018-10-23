defmodule PhxDiff.Diffs do
  @sample_app_path "data/sample-app"
  @diffs_path "data/diffs"

  def all_versions do
    @sample_app_path
    |> File.ls!()
    |> Enum.sort_by(&Version.parse!/1, &(Version.compare(&1, &2) == :lt))
  end

  def release_versions, do: all_versions() |> Enum.reject(&pre_release?/1)

  defp pre_release?(version), do: !Enum.empty?(Version.parse!(version).pre)

  def latest_version, do: all_versions() |> List.last()

  def previous_release_version do
    releases = release_versions()
    latest_release = releases |> List.last()

    if latest_version() == latest_release do
      releases |> Enum.at(-2)
    else
      latest_release
    end
  end
end
