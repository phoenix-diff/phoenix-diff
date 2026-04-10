defmodule PhxDiffWeb.LLMTextController do
  use PhxDiffWeb, :controller

  @body """
  # PhxDiff

  PhxDiff generates diffs between Phoenix Framework versions so you can upgrade your app.

  Endpoints are machine-readable. Listings and diffs are plain text, `/compare/<source>...<target>/diff/manifest` returns JSON, and `/browse/<app_spec>/raw/<path>` returns the file's content type. Generated apps use the name `sample_app` / `SampleApp` — replace these with your app's actual names.

  ## Endpoints

  GET /versions — list all versions and their available app specs
  GET /compare/<source>...<target>/diff — unified diff between two versions
  GET /compare/<source>...<target>/diff/manifest — normalized JSON change manifest for LLMs
  GET /browse/<app_spec>/files.txt — list all files in a generated app
  GET /browse/<app_spec>/raw/<path> — fetch a specific file from a generated app

  ## App specs

  An app spec is a version string optionally followed by a phx.new flag, separated by a space.
  Use the app specs exactly as listed in /versions.

  Note: spaces in app specs must be encoded as %20 in URLs.

  Examples:
    /browse/1.7.10/files.txt                          (default, no flag)
    /browse/1.7.10%20--umbrella/files.txt             (umbrella flag)
    /browse/1.7.10/raw/config/dev.exs                 (fetch a file, no flag)
    /browse/1.7.10%20--umbrella/raw/config/dev.exs    (fetch a file, umbrella flag)
  """

  def show(conn, _params) do
    conn
    |> put_resp_content_type("text/plain", nil)
    |> send_resp(200, @body)
  end
end
