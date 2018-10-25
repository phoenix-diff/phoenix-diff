defmodule Mix.Tasks.PhxDiff.Gen.Sample do
  use Mix.Task

  @shortdoc "Generate a sample app for a phoenix version"

  def run(args) do
    if length(args) == 1 do
      Mix.Tasks.Cmd.run(["./bin/generate-sample-app"] ++ args)
    else
      Mix.shell().error([:red, "A phoenix version must be specified"])
    end
  end
end
