defmodule PhxDiff.OpenTelemetry do
  @moduledoc false

  @tracer_id __MODULE__

  require OpenTelemetry.Tracer
  alias OpenTelemetry.Span

  @diff_generate_start_event [:phx_diff, :diffs, :generate, :start]
  @diff_generate_stop_event [:phx_diff, :diffs, :generate, :stop]
  @diff_generate_exception_event [:phx_diff, :diffs, :generate, :exception]

  def setup do
    :telemetry.attach_many(
      __MODULE__,
      [
        @diff_generate_start_event,
        @diff_generate_stop_event,
        @diff_generate_exception_event
      ],
      &__MODULE__.phx_diff_diffs_generate/4,
      :ok
    )
  end

  @doc false
  def phx_diff_diffs_generate(@diff_generate_start_event, _, metadata, _) do
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

  def phx_diff_diffs_generate(@diff_generate_stop_event, %{duration: duration}, meta, _) do
    ctx = OpentelemetryTelemetry.set_current_telemetry_span(@tracer_id, meta)

    set_duration(ctx, duration)

    OpentelemetryTelemetry.end_telemetry_span(@tracer_id, meta)
  end

  def phx_diff_diffs_generate(@diff_generate_exception_event, _, meta, _) do
    ctx = OpentelemetryTelemetry.set_current_telemetry_span(@tracer_id, meta)
    %{kind: kind, reason: reason, stacktrace: stacktrace} = meta

    # try to normalize all errors to Elixir exceptions
    exception = Exception.normalize(kind, reason, stacktrace)

    # record exception and mark the span as errored
    Span.record_exception(ctx, exception, stacktrace)
    Span.set_status(ctx, OpenTelemetry.status(:error, ""))

    OpentelemetryTelemetry.end_telemetry_span(@tracer_id, meta)
  end

  defp set_duration(ctx, duration) do
    duration_ms = System.convert_time_unit(duration, :native, :millisecond)
    Span.set_attribute(ctx, :duration_ms, duration_ms)
  end
end
