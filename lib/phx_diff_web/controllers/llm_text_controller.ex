defmodule PhxDiffWeb.LLMTextController do
  use PhxDiffWeb, :controller

  @body """
  # PhxDiff

  PhxDiff generates diffs between Phoenix Framework versions so you can upgrade your app.

  All endpoints return plain text. Generated apps use the name `sample_app` / `SampleApp` — replace these with your app's actual names.

  ## Endpoints

  GET /versions — list all versions and their available app specs
  GET /compare/<source>...<target>/diff — unified diff between two app versions (returns raw text; fetch with curl, not a browser-based tool)
  GET /compare/<source>...<target>/diff/stat — summary of changed files and line counts
  GET /browse/<app_spec>/files.txt — list all files in a generated app
  GET /browse/<app_spec>/raw/<path> — fetch a specific file from a generated app

  The separator between source and target is three dots (not two): 1.7.21...1.8.5

  ## App specs

  An app spec is a version string optionally followed by a phx.new flag, separated by a space.
  Use the app specs exactly as listed in /versions.

  Note: spaces in app specs must be encoded as %20 in URLs.

  Examples:
    /browse/1.7.10/files.txt                          (default, no flag)
    /browse/1.7.10%20--umbrella/files.txt             (umbrella flag)
    /browse/1.7.10/raw/config/dev.exs                 (fetch a file, no flag)
    /browse/1.7.10%20--umbrella/raw/config/dev.exs    (fetch a file, umbrella flag)

  ## How to upgrade a Phoenix app

  1. GET /versions — find available versions and supported variants
  2. GET /compare/<source>...<target>/diff/stat — check the scope of changes
  3. GET /compare/<source>...<target>/diff — get the full diff (add ?exclude[]=assets/vendor to skip vendored files)
  4. Apply the diff, replacing `sample_app`/`SampleApp` with your app's actual names

  ## Diff options

  ?exclude[]=<path_prefix> — exclude files under a path prefix from the diff (repeatable)
  Examples:
    /compare/1.7.10...1.8.0/diff?exclude[]=assets/vendor
    /compare/1.7.10...1.8.0/diff?exclude[]=assets/vendor&exclude[]=mix.lock
  """

  def show(conn, _params) do
    conn
    |> put_resp_content_type("text/plain", nil)
    |> send_resp(200, @body)
  end
end
