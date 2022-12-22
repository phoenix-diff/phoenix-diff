defmodule PhxDiff.Logger do
  @moduledoc false

  alias PhxDiff.AppSpecification

  require Logger

  def install do
    handlers = %{
      [:phx_diff, :diffs, :generate, :start] => &__MODULE__.phx_diff_diffs_generate_start/4,
      [:phx_diff, :diffs, :generate, :stop] => &__MODULE__.phx_diff_diffs_generate_stop/4
    }

    for {event, handler} <- handlers do
      :telemetry.attach(
        {__MODULE__, event},
        event,
        handler,
        :ok
      )
    end
  end

  @doc false
  def phx_diff_diffs_generate_start(_, _, metadata, _) do
    %{source_spec: source, target_spec: target} = metadata

    Logger.info(["Comparing ", app_spec(source), " to ", app_spec(target)],
      "event.domain": "diffs",
      "event.name": "compare.start",
      "phx_diff.comparison.source_version": to_string(source.phoenix_version),
      "phx_diff.comparison.source_phx_new_arguments": Enum.join(source.phx_new_arguments, " "),
      "phx_diff.comparison.target_version": to_string(target.phoenix_version),
      "phx_diff.comparison.target_phx_new_arguments": Enum.join(target.phx_new_arguments, " ")
    )
  end

  @doc false
  def phx_diff_diffs_generate_stop(_, _metrics, %{error: error}, _) do
    Logger.warning(["Unable to generate diff - \r\n", inspect(error, pretty: true)],
      "event.domain": "diffs"
    )
  end

  def phx_diff_diffs_generate_stop(_, %{duration: duration}, _metadata, _) do
    Logger.info(["Generated in ", duration(duration)], "event.domain": "diffs")
  end

  defp app_spec(%AppSpecification{} = app_spec) do
    flags_segment =
      case app_spec.phx_new_arguments do
        [] -> []
        args -> [" ", Enum.intersperse(args, " ")]
      end

    ["\"", app_spec.phoenix_version |> to_string(), flags_segment, "\""]
  end

  defp duration(duration) do
    duration = System.convert_time_unit(duration, :native, :microsecond)

    if duration > 1000 do
      [duration |> div(1000) |> Integer.to_string(), "ms"]
    else
      [Integer.to_string(duration), "µs"]
    end
  end
end
