defmodule PhxDiff.Diffs.DiffEngine do
  @moduledoc false

  alias PhxDiff.Diffs.AppRepo

  @type version :: PhxDiff.Diffs.version()
  @type diff :: PhxDiff.Diffs.diff()

  @diffs_path "data/diffs"

  @spec get_diff(version, version) :: {:ok, diff} | {:error, :invalid_versions}
  def get_diff(source_version, target_version) do
    case File.read(diff_file_path(source_version, target_version)) do
      {:error, _} -> {:error, :invalid_versions}
      result -> result
    end
  end

  @spec generate :: :ok
  def generate do
    versions = AppRepo.all_versions()

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
    {:ok, source_path} = AppRepo.fetch_app_path(source_version)
    {:ok, target_path} = AppRepo.fetch_app_path(target_version)

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
