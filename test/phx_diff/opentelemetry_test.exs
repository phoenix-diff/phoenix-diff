defmodule PhxDiff.OpenTelemetryTest do
  use ExUnit.Case, async: false

  import PhxDiff.TestSupport.OpenTelemetryTestExporter, only: [subscribe_to_otel_spans: 1]
  import PhxDiff.TestSupport.Sigils

  describe "diff events" do
    @diff_event_prefix [:phx_diff, :diffs, :generate]

    setup [:subscribe_to_otel_spans]

    test "an exception is reported properly" do
      metadata = %{
        source_spec: PhxDiff.default_app_specification(~V[1.3.1]),
        target_spec: PhxDiff.default_app_specification(~V[1.3.2])
      }

      assert_raise RuntimeError, fn ->
        :telemetry.span(@diff_event_prefix, metadata, fn ->
          raise "foo"
        end)
      end

      assert_receive(
        {:otel_span,
         %{
           name: :"PhxDiff.Diffs.get_diff/3",
           status: %{code: :error},
           events: [%{name: "exception"} = exception_event]
         }}
      )

      assert exception_event.attributes["exception.type"] == "Elixir.RuntimeError"
      assert exception_event.attributes["exception.message"] == "foo"
    end

    test "when something is thrown" do
      metadata = %{
        source_spec: PhxDiff.default_app_specification(~V[1.3.1]),
        target_spec: PhxDiff.default_app_specification(~V[1.3.2])
      }

      catch_throw(
        :telemetry.span(@diff_event_prefix, metadata, fn ->
          throw(:baddarg)
        end)
      )

      assert_receive(
        {:otel_span, %{name: :"PhxDiff.Diffs.get_diff/3", status: %{code: :error}} = span}
      )

      assert span.events == []
    end
  end
end
