defmodule PhxDiff.Diffs.DiffEngine do
  @moduledoc false

  @type diff :: PhxDiff.Diffs.diff()

  @spec compute_diff(String.t(), String.t()) :: diff
  def compute_diff(source_path, target_path) do
    {result, _exit_code} = System.cmd("diff", ["-ruN", source_path, target_path])

    result
    |> String.replace("#{source_path}/", "")
    |> String.replace("#{target_path}/", "")
  end
end
