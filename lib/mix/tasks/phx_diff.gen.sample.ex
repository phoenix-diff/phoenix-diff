defmodule Mix.Tasks.PhxDiff.Gen.Sample do
  @moduledoc false
  alias PhxDiff.AppSpecification
  use Mix.Task

  use Boundary, deps: [PhxDiff]

  @shortdoc "Generate a sample app for a phoenix version"

  def run(args) when is_list(args) do
    with {:ok, version_arg, remaining_args} <- pop_version_arg(args),
         {:ok, version} <- parse_version(version_arg),
         {:ok, app_path} <- generate_app_path(AppSpecification.new(version, remaining_args)) do
      app_path = Path.relative_to(app_path, Application.app_dir(:phx_diff))

      Mix.shell().info("""

      Successfully generated sample app.

      To add this to version control, run:

          git add #{app_path}
          git add -f #{app_path}/config/prod.secret.exs
      """)
    else
      {:error, :invalid_version, version} ->
        Mix.shell().error([:red, "Invalid version: ", inspect(version)])

      {:error, :unknown_version, app_spec} ->
        Mix.shell().error([
          [
            :red,
            "Unknown version: ",
            app_spec.phoenix_version |> to_string() |> inspect(),
            :reset,
            "\n"
          ],
          "\n",
          "Available phoenix versions are listed here:\n",
          "\n",
          "    https://hex.pm/packages/phoenix/versions"
        ])

      {:error, :no_version_arg} ->
        Mix.shell().error([:red, "A phoenix version must be specified"])
    end
  end

  defp pop_version_arg(args) do
    case List.pop_at(args, 0) do
      {nil, _remaining_args} ->
        {:error, :no_version_arg}

      {version_arg, remaining_args} ->
        {:ok, version_arg, remaining_args}
    end
  end

  defp parse_version(arg) do
    case Version.parse(arg) do
      {:ok, version} -> {:ok, version}
      :error -> {:error, :invalid_version, arg}
    end
  end

  def generate_app_path(app_specification) do
    case PhxDiff.generate_sample_app(app_specification) do
      {:ok, app_path} -> {:ok, app_path}
      {:error, :unknown_version} -> {:error, :unknown_version, app_specification}
    end
  end
end
