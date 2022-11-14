defmodule Mix.Tasks.PhxDiff.Gen.Sample do
  @moduledoc false
  use Mix.Task

  use Boundary, deps: [PhxDiff]

  @shortdoc "Generate a sample app for a phoenix version"

  def run([arg]) do
    with {:ok, version} <- parse_version(arg),
         {:ok, app_path} <- generate_app_path(version) do
      app_path = Path.relative_to(app_path, Application.app_dir(:phx_diff))

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

  defp parse_version(arg) do
    case Version.parse(arg) do
      {:ok, version} -> {:ok, version}
      :error -> {:error, :invalid_version}
    end
  end

  def generate_app_path(version) do
    version
    |> PhxDiff.default_app_specification()
    |> PhxDiff.generate_sample_app()
  end
end
