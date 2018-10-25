defmodule Mix.Tasks.PhxDiff.Gen.Diffs do
  use Mix.Task

  @shortdoc "Generate diffs for existing sample apps"

  def run(_) do
    Mix.shell().info([:yellow, "Generating diffs..."])
    PhxDiff.Diffs.generate()
    Mix.shell().info([:green, "Completed generating diffs"])
  end
end
