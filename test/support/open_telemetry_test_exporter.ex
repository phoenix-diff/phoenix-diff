defmodule PhxDiff.TestSupport.OpenTelemetryTestExporter do
  @moduledoc """
  An OpenTelemetry exporter that echos span messages to the registered process

  To set up, add the following to test_helper.exs

      :otel_batch_processor.set_exporter(#{inspect(__MODULE__)})
  """

  import Record, only: [is_record: 2]

  alias PhxDiff.TestSupport.OpenTelemetryTestExporter.Records

  require Records

  @behaviour :otel_exporter

  @registry __MODULE__

  @impl :otel_exporter
  def init(_opt) do
    Registry.start_link(keys: :duplicate, name: @registry)
    {:ok, nil}
  end

  @impl :otel_exporter
  def export(spans_tid, _Resource, _state) do
    :ets.foldl(
      fn span, _acc ->
        normalized_span = normalize_span(span)

        Registry.dispatch(@registry, :subscriber, fn entries ->
          for {pid, _} <- entries, do: send(pid, {:otel_span, normalized_span})
        end)
      end,
      [],
      spans_tid
    )

    :ok
  end

  @impl :otel_exporter
  def shutdown(_opt) do
    GenServer.stop(@registry)
    :ok
  end

  @doc """
  Subscribes the current process to otel span events

  The process will receive messages like

      {:otel_span, span}
  """
  def subscribe_to_otel_spans(_) do
    Registry.register(@registry, :subscriber, [])
    :ok
  end

  defp normalize_span(span) when is_record(span, :span) do
    span
    |> Records.span()
    |> Map.new(fn
      {key, :undefined} ->
        {key, :undefined}

      {:attributes, val} ->
        {:attributes, :otel_attributes.map(val)}

      {:events, val} ->
        {:events, val |> :otel_events.list() |> Enum.map(&normalize_event/1)}

      {:links, val} ->
        {:otel_links, :otel_links.list(val)}

      {:instrumentation_library, val} ->
        {:instrumentation_library, val |> Records.instrumentation_library() |> Map.new()}

      {:status, val} ->
        {:status, val |> Records.status() |> Map.new()}

      {key, val} ->
        {key, val}
    end)
  end

  defp normalize_event(event) when is_record(event, :event) do
    event
    |> Records.event()
    |> Map.new(fn
      {key, :undefined} ->
        {key, :undefined}

      {:attributes, val} ->
        {:attributes, :otel_attributes.map(val)}

      {key, val} ->
        {key, val}
    end)
  end
end
