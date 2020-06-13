defmodule PhxDiff.Diffs do
  @sample_app_path "data/sample-app"
  @diffs_path "data/diffs"

  @type diff :: String.t()
  @type version :: String.t()

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

  @spec get_diff(version, version) :: {:ok, diff} | {:error, :invalid_versions}
  def get_diff(source_version, target_version) do
    case File.read(diff_file_path(source_version, target_version)) do
      {:error, _} -> {:error, :invalid_versions}
      result -> result
    end
  end

  @spec generate :: :ok
  def generate do
    versions = all_versions()

    version_tuples =
      Enum.concat(
        Enum.map(versions, fn source_version ->
          Enum.map(versions, fn target_version ->
            {source_version, target_version}
          end)
        end)
      )

    _ =
      version_tuples
      |> Task.async_stream(&generate_diff_content/1)
      |> Enum.to_list()

    :ok
  end

  defp generate_diff_content({source_version, target_version}) do
    source_path = "#{@sample_app_path}/#{source_version}"
    target_path = "#{@sample_app_path}/#{target_version}"

    {result, _exit_code} = System.cmd("git", ["diff", "--no-index", source_path, target_path])

    content =
      result
      |> String.replace("a/#{source_path}/", "")
      |> String.replace("b/#{target_path}/", "")

    File.write!(diff_file_path(source_version, target_version), content)
  end

  defp diff_file_path(source_version, target_version) do
    "#{@diffs_path}/#{source_version}--#{target_version}.diff"
  end
end
