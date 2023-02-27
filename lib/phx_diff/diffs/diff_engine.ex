defmodule PhxDiff.Diffs.DiffEngine do
  @moduledoc false

  @type diff :: PhxDiff.Diffs.diff()

  @spec compute_diff(String.t(), String.t()) :: diff
  def compute_diff(source_path, target_path) do
    {:ok, diff} = git_diff(source_path, target_path)

    diff
    |> String.replace(~r/((?:a|b)+)#{source_path}\//, "\\1/")
    |> String.replace(~r/((?:a|b)+)#{target_path}\//, "\\1/")
    # This updates the renames which don't have the a/b prefix and ensures we
    # don't put a leading slash on these paths
    |> String.replace(~r/#{source_path}\//, "")
    |> String.replace(~r/#{target_path}\//, "")
  end

  defp git_diff(source_path, target_path) do
    case System.cmd("git", [
           "-c",
           "core.quotepath=false",
           "-c",
           "diff.algorithm=histogram",
           "diff",
           "--no-index",
           "--no-color",
           source_path,
           target_path
         ]) do
      {"", 0} -> {:ok, ""}
      {output, 1} -> {:ok, output}
      other -> {:error, other}
    end
  end
end
