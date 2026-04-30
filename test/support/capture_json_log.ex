defmodule PhxDiff.CaptureJSONLog do
  @moduledoc """
  Captures and parses JSON log output
  """

  # TODO: Rework this once Elixir 1.20 lands with the {:formatter, ...} capture_log option.
  @dialyzer {:nowarn_function, capture_json_log: 1}
  @dialyzer {:nowarn_function, parse_json_logs: 1}
  @spec capture_json_log((-> any())) :: [map()]
  def capture_json_log(function) when is_function(function) do
    ExUnit.CaptureLog.capture_log(
      [
        format: {PhxDiff.Logging.Formatter, :format},
        colors: [enabled: false],
        metadata: :all
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
