defmodule Mix.Tasks.PhxDiff.Gen.Sample do
  @moduledoc false
  use Mix.Task

  alias PhxDiff.Diffs

  @shortdoc "Generate a sample app for a phoenix version"

  def run([arg]) do
    with {:ok, app_spec} <- Diffs.fetch_default_app_specification(arg),
         {:ok, app_path} <- Diffs.generate_sample_app(app_spec) do
      Mix.shell().info("""

      Successfully generated sample app.

      To add this to version control, run:

          git add #{app_path}
          git add -f #{app_path}/config/prod.secret.exs
      """)
    else
      {:error, :invalid_version} ->
        Mix.shell().error([:red, "Invalid version: ", inspect(arg)])

      {:error, :unknown_version} ->
        Mix.shell().error([
          [:red, "Unknown version: ", inspect(arg), :reset, "\n"],
          "\n",
          "Available phoenix versions are listed here:\n",
          "\n",
          "    https://hex.pm/packages/phoenix/versions"
        ])
    end
  end

  def run(_) do
    Mix.shell().error([:red, "A phoenix version must be specified"])
  end
end
