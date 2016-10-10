defmodule PhoenixDiff.Diff do
  @sample_app_path "data/sample-app"

  def get(from_version, to_version) do
    # git diff --no-index data/sample-app/1.0.1 data/sample-app/1.2.0
    {result, _exit_code} = System.cmd("git", ["diff",
                                              "--no-index",
                                              "#{@sample_app_path}/#{from_version}",
                                              "#{@sample_app_path}/#{to_version}"]) |> IO.inspect

    result
  end
end
