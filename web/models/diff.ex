defmodule PhoenixDiff.Diff do
  @sample_app_path "data/sample-app"

  def available_versions, do: @sample_app_path |> File.ls! |> Enum.sort

  def get(from_version, to_version) do
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
