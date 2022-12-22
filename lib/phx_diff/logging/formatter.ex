defmodule PhxDiff.Logging.Formatter do
  @moduledoc false

  import Jason.Helpers

  def format(level, message, timestamp, metadata) do
    event =
      %{
        message: IO.iodata_to_binary(message),
        syslog: json_map(timestamp: format_datetime(timestamp)),
        level: Atom.to_string(level)
      }
      |> Map.merge(known_metadata_attributes(metadata))
      |> Map.merge(trace_attributes(metadata))
      |> Map.merge(phx_diff_attributes(metadata))

    [Jason.encode_to_iodata!(event), "\n"]
  end

  defp format_datetime({date, time}) do
    [Logger.Formatter.format_date(date), ?T, Logger.Formatter.format_time(time), ?Z]
    |> IO.iodata_to_binary()
  end

  defp known_metadata_attributes(metadata) do
    Keyword.take(metadata, [:"event.domain", :"event.name"])
    |> Map.new()
  end

  defp trace_attributes(metadata) do
    Enum.flat_map(metadata, fn
      {:otel_trace_id, trace_id} -> ["trace.id": to_string(trace_id)]
      _ -> []
    end)
    |> Map.new()
  end

  defp phx_diff_attributes(metadata) do
    metadata
    |> Enum.filter(fn {k, _v} ->
      k |> to_string() |> String.starts_with?("phx_diff.")
    end)
    |> Map.new()
  end
end
