defmodule Mix.Tasks.PhxDiff.Add do
  use Mix.Task

  @shortdoc "Add a version of phoenix to phoenix diff"

  def run(args) do
    Mix.Tasks.PhxDiff.Gen.Sample.run(args)
    Mix.Tasks.PhxDiff.Gen.Diffs.run(args)
  end
end
