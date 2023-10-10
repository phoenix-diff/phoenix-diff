defmodule PhxDiff.Diffs.DiffEngine do
  @moduledoc false

  @type diff :: PhxDiff.Diffs.diff()

  @spec compute_diff(String.t(), String.t()) :: diff
  def compute_diff(source_path, target_path) do
    # TODO: The diff itself takes a lot of memory, but each replacement adds to it as well

    # {:ok, diff} = git_diff(source_path, target_path)

    workspace_path = tmp_dir_path()
    File.mkdir_p!(workspace_path)

    file_path = Path.join(workspace_path, "#{random_string()}.diff")
    file_stream = File.stream!(file_path)

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
         ], into: file_stream) do
           {_stream, status} when status in [0, 1] ->
             :ok
         end

    file_stream
    |> Enum.join()
    |> IO.puts()
    # |> GitDiff.stream_patch(relative_from: source_path, relative_to: target_path)
    # |> Stream.run()

    ""
    # diff
    # |> String.replace(~r/((?:a|b)+)#{source_path}\//, "\\1/")
    # |> String.replace(~r/((?:a|b)+)#{target_path}\//, "\\1/")
    # # This updates the renames which don't have the a/b prefix and ensures we
    # # don't put a leading slash on these paths
    # |> String.replace(~r/#{source_path}\//, "")
    # |> String.replace(~r/#{target_path}\//, "")
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

  defp random_string do
    Base.encode16(:crypto.strong_rand_bytes(4))
  end

  defp tmp_dir_path do
    Path.join([System.tmp_dir!(), "diff-workspace"])
  end
end
