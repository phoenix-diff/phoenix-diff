defmodule PhxDiff.Logging.FormatterTest do
  use ExUnit.Case, async: true

  import PhxDiff.CaptureJSONLog

  require Logger

  test "properly formats a log message as JSON" do
    log_msg = "Hello from #{inspect(__MODULE__)}"

    assert json_log =
             capture_json_log(fn -> Logger.info(log_msg) end)
             |> Enum.find(&match?(%{"message" => ^log_msg}, &1))

    assert {:ok, _date, _} = DateTime.from_iso8601(json_log["syslog"]["timestamp"])
    assert json_log["level"] == "info"
  end
end
