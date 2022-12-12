defmodule PhxDiff.CaptureJSONLog do
  @moduledoc """
  Captures and parses JSON log output
  """

  def capture_json_log(function) when is_function(function) do
    ExUnit.CaptureLog.capture_log(
      [
        format: {PhxDiff.Logging.Formatter, :format},
        colors: [enabled: false]
      ],
      function
    )
    |> parse_json_logs()
  end

  defp parse_json_logs(raw_logs) do
    for {:ok, parsed} <- raw_logs |> String.split("\n", trim: true) |> Enum.map(&Jason.decode/1),
        do: parsed
  end
end
