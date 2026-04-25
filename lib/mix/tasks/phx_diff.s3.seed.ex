defmodule Mix.Tasks.PhxDiff.S3.Seed do
  @moduledoc false

  use Mix.Task
  use Boundary, deps: [PhxDiff]

  @shortdoc "Upload local sample apps to S3"

  @impl Mix.Task
  def run(args) when is_list(args) do
    Mix.Task.run("app.start")

    with {:ok, options} <- parse_options(args),
         {:ok, results} <- PhxDiff.seed_s3_sample_apps(options) do
      results
      |> print_results()
      |> print_summary()
      |> maybe_exit_with_failure()
    else
      {:error, :unable_to_list_local_apps} ->
        Mix.shell().error([:red, "Unable to list local sample apps"])
        exit({:shutdown, 1})
    end
  end

  defp parse_options(args) do
    {options, _remaining_args, invalid} =
      OptionParser.parse(args,
        strict: [force: :boolean, version: :string, variant: :string],
        aliases: [f: :force]
      )

    case invalid do
      [] -> {:ok, options}
      [{option, _value} | _] -> {:error, "Unknown option: #{option}"}
    end
  end

  defp print_results(results) do
    Enum.each(results, fn
      %{status: :uploaded, path: path, key: key} ->
        Mix.shell().info("Uploaded #{path} to #{key}")

      %{status: :skipped, path: path, key: key} ->
        Mix.shell().info("Skipped #{path} because #{key} already exists")

      %{status: :failed, path: path} ->
        Mix.shell().error("Failed #{path}")
    end)

    results
  end

  defp print_summary(results) do
    uploaded = count_status(results, :uploaded)
    skipped = count_status(results, :skipped)
    failed = count_status(results, :failed)
    Mix.shell().info("Uploaded: #{uploaded}; skipped: #{skipped}; failed: #{failed}")

    %{uploaded: uploaded, skipped: skipped, failed: failed}
  end

  defp maybe_exit_with_failure(%{failed: 0}), do: :ok
  defp maybe_exit_with_failure(_summary), do: exit({:shutdown, 1})

  defp count_status(results, status), do: Enum.count(results, &(&1.status == status))
end
