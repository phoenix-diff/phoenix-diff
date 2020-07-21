defmodule Mix.Tasks.Yarn do
  @moduledoc false
  use Mix.Task

  @shortdoc "Run yarn within assets directory"

  @default_args ~w(--color)

  def run(args) do
    yarn_args = args ++ @default_args

    "yarn"
    |> System.cmd(yarn_args, into: IO.stream(:stdio, :line), cd: "assets")
    |> halt_on_error
  end

  defp halt_on_error({_, 0} = result), do: result

  defp halt_on_error({_, exit_code}) do
    Mix.raise("mix yarn failed with exit code #{exit_code}")
  end
end
