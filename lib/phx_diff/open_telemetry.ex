defmodule PhxDiff.OpenTelemetry do
  @moduledoc false

  @tracer_id __MODULE__

  require OpenTelemetry.Tracer
  alias OpenTelemetry.Span

  def setup do
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

    attributes = [
      "diff.source_phoenix_version": to_string(source.phoenix_version),
      "diff.target_phoenix_version": to_string(target.phoenix_version)
    ]

    OpentelemetryTelemetry.start_telemetry_span(
      @tracer_id,
      :"PhxDiff.Diffs.get_diff/3",
      metadata,
      %{
        kind: :internal,
        attributes: attributes
      }
    )
  end

  def phx_diff_diffs_generate_stop(_, %{duration: duration}, meta, _) do
    ctx = OpentelemetryTelemetry.set_current_telemetry_span(@tracer_id, meta)

    set_duration(ctx, duration)

    OpentelemetryTelemetry.end_telemetry_span(@tracer_id, meta)
  end

  defp set_duration(ctx, duration) do
    duration_ms = System.convert_time_unit(duration, :native, :millisecond)
    Span.set_attribute(ctx, :duration_ms, duration_ms)
  end
end
