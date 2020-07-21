defmodule Mix.Tasks.PhxDiff.Add do
  @moduledoc false
  use Mix.Task

  alias Mix.Tasks.PhxDiff.Gen

  @shortdoc "Add a version of phoenix to phoenix diff"

  def run(args) do
    Gen.Sample.run(args)
  end
end
