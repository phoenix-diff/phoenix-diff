defmodule PhxDiff.TestSupport.TelemetryHelpers do
  @moduledoc """
  Test helpers for ensuring `:telemetry` events are emitted properly.
  """

  @doc """
  Subscribes to a list of telemetry events.

  To assert the events are sent or not sent, use the following helpers.

  * `assert_received_telemetry_event/2`
  * `refute_received_telemetry_event/2`
  """
  def subscribe_to_telemetry_events(%{async: true}, _) do
    raise ArgumentError, """
    tests using `subscribe_to_telemetry_events/1` are not compatible with `async: true`

      :telemetry is a global message bus which is shared between tests, so running
      multiple tests concurrently can lead to unexpected results.
    """
  end

  def subscribe_to_telemetry_events(context, events) do
    test_pid = self()

    :telemetry.attach_many(
      {context.module, context.test},
      events,
      &__MODULE__.__echo_telemetry_event__/4,
      %{test_pid: test_pid}
    )
  end

  @doc false
  def __echo_telemetry_event__(event, measures, metadata, %{test_pid: test_pid} = config) do
    send(test_pid, {:telemetry_event, event, {measures, metadata}, config})
  end

  @doc """
  Assert a telemetry event was sent.

  To subscribe to events, use `subscribe_to_telemetry_events/2` in the current test process.
  """
  defmacro assert_received_telemetry_event(event_name, match) do
    quote do
      test_pid = self()

      assert_received {:telemetry_event, unquote(event_name), unquote(match),
                       %{test_pid: ^test_pid}}
    end
  end

  @doc """
  Refute a telemetry event was sent.

  To subscribe to events, use `subscribe_to_telemetry_events/2` in the current test process.
  """
  defmacro refute_received_telemetry_event(event_name, match) do
    quote do
      test_pid = self()

      refute_received {:telemetry_event, unquote(event_name), unquote(match),
                       %{test_pid: ^test_pid}}
    end
  end
end
