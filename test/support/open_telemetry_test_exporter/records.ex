defmodule PhxDiff.TestSupport.OpenTelemetryTestExporter.Records do
  @moduledoc false

  require Record

  :span
  |> Record.extract(from_lib: "opentelemetry/include/otel_span.hrl")
  |> then(&Record.defrecord(:span, &1))

  :instrumentation_library
  |> Record.extract(from_lib: "opentelemetry_api/include/opentelemetry.hrl")
  |> then(&Record.defrecord(:instrumentation_library, &1))
end
