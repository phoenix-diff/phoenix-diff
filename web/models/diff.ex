defmodule PhoenixDiff.Diff do
  @sample_app_path "data/sample-app"
  @diffs_path "data/diffs"

  def available_versions, do: @sample_app_path |> File.ls! |> Enum.sort

  def store_diffs do
    versions = available_versions()
    for from_version <- versions do
      for to_version <- versions do
        File.write! diff_file_path(from_version, to_version), generate(from_version, to_version)
      end
    end
  end

  def get(from_version, to_version) do
    case File.read(diff_file_path(from_version, to_version)) do
      {:ok, content} -> content
      _ -> ""
    end
  end

  defp diff_file_path(from_version, to_version), do: "#{@diffs_path}/#{from_version}--#{to_version}.diff"

  defp generate(from_version, to_version) do
    from_path = "#{@sample_app_path}/#{from_version}"
    to_path = "#{@sample_app_path}/#{to_version}"

    {result, _exit_code} = System.cmd("git", ["diff",
                                              "--no-index",
                                              from_path,
                                              to_path])

    result
    |> String.replace("a/#{from_path}/", "")
    |> String.replace("b/#{to_path}/", "")
  end
end
