defmodule Mix.Tasks.PhxDiff.Gen.Sample do
  @moduledoc false
  use Mix.Task

  alias PhxDiff.Diffs
  alias PhxDiff.Diffs.AppSpecification

  @shortdoc "Generate a sample app for a phoenix version"

  def run([arg]) do
    arg
    |> AppSpecification.new()
    |> Diffs.generate_sample_app()
    |> case do
      {:ok, app_path} ->
        Mix.shell().info("""

        Successfully generated sample app.

        To add this to version control, run:

            git add #{app_path}
            git add -f #{app_path}/config/prod.secret.exs
        """)

        :ok

      {:error, :invalid_version} ->
        Mix.shell().error([:red, "Invalid version: ", inspect(arg)])
    end
  end

  def run(_) do
    Mix.shell().error([:red, "A phoenix version must be specified"])
  end
end
