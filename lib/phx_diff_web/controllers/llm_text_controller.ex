defmodule PhxDiffWeb.LLMTextController do
  use PhxDiffWeb, :controller

  @body """
  # PhxDiff

  PhxDiff generates diffs between Phoenix Framework versions so you can upgrade your app.

  All endpoints return plain text. Generated apps use the name `sample_app` / `SampleApp` — replace these with your app's actual names.

  ## Endpoints

  GET /versions — list all versions and their available app specs
  GET /browse/<app_spec>/files.txt — list all files in a generated app
  GET /browse/<app_spec>/raw/<path> — fetch a specific file from a generated app

  ## App specs

  An app spec is a version string optionally followed by a phx.new flag, separated by a space.
  Use the app specs exactly as listed in /versions, URL-encoding spaces as %20.

  Examples:
    /browse/1.7.10/raw/config/dev.exs          (no flag)
    /browse/1.7.10%20--umbrella/raw/config/dev.exs
  """

  def show(conn, _params) do
    conn
    |> put_resp_content_type("text/plain", nil)
    |> send_resp(200, @body)
  end
end
