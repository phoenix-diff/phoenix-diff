defmodule PhxDiff.TestSupport.OpenTelemetryTestExporter.Records do
  @moduledoc false

  require Record

  for record_name <- [:span, :event] do
    record_name
    |> Record.extract(from_lib: "opentelemetry/include/otel_span.hrl")
    |> then(&Record.defrecord(record_name, &1))
  end

  for record_name <- [:instrumentation_scope, :status] do
    record_name
    |> Record.extract(from_lib: "opentelemetry_api/include/opentelemetry.hrl")
    |> then(&Record.defrecord(record_name, &1))
  end
end
