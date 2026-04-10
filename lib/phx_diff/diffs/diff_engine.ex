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
           "--src-prefix=a/",
           "--dst-prefix=b/",
           source_path,
           target_path
         ]) do
      {"", 0} -> {:ok, ""}
      {output, 1} -> {:ok, output}
      other -> {:error, other}
    end
  end

  @spec compute_numstat(String.t(), String.t()) :: {:ok, [{String.t(), String.t(), String.t()}]}
  def compute_numstat(source_path, target_path) do
    case git_numstat(source_path, target_path) do
      {:ok, output} ->
        entries = parse_numstat(output, source_path, target_path)
        {:ok, entries}
    end
  end

  defp git_numstat(source_path, target_path) do
    case System.cmd("git", [
           "-c",
           "core.quotepath=false",
           "diff",
           "--no-index",
           "-M",
           "--numstat",
           "-z",
           "--diff-algorithm=histogram",
           "--",
           source_path,
           target_path
         ]) do
      {"", 0} -> {:ok, ""}
      {output, 1} -> {:ok, output}
      other -> {:error, other}
    end
  end

  defp parse_numstat("", _source_path, _target_path), do: []

  defp parse_numstat(output, source_path, target_path) do
    output
    |> String.split("\0", trim: true)
    |> chunk_triples([])
    |> Enum.map(fn [stats, old_path, new_path] ->
      {stats, strip_prefix(old_path, source_path), strip_prefix(new_path, target_path)}
    end)
  end

  defp chunk_triples([], acc), do: Enum.reverse(acc)
  defp chunk_triples([a, b, c | rest], acc), do: chunk_triples(rest, [[a, b, c] | acc])
  defp chunk_triples([_ | _], acc), do: Enum.reverse(acc)

  defp strip_prefix("/dev/null", _prefix), do: "/dev/null"
  defp strip_prefix(path, prefix), do: String.replace_prefix(path, prefix <> "/", "")
end
