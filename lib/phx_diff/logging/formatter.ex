defmodule PhxDiff.Logging.Formatter do
  @moduledoc false

  import Jason.Helpers

  def format(level, message, timestamp, _metadata) do
    event =
      json_map(
        message: IO.iodata_to_binary(message),
        syslog: json_map(timestamp: format_datetime(timestamp)),
        level: Atom.to_string(level)
      )

    [Jason.encode_to_iodata!(event), "\n"]
  end

  defp format_datetime({date, time}) do
    [Logger.Formatter.format_date(date), ?T, Logger.Formatter.format_time(time), ?Z]
    |> IO.iodata_to_binary()
  end
end
