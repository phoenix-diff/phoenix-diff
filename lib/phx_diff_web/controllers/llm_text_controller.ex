defmodule PhxDiffWeb.LLMTextController do
  use PhxDiffWeb, :controller

  @body """
  # PhxDiff

  PhxDiff generates diffs between Phoenix Framework versions so you can upgrade your app.

  Endpoints are machine-readable. Listings and diffs are plain text, `/compare/<source_app_spec>...<target_app_spec>/diff/manifest` returns JSON, and `/browse/<app_spec>/raw/<path>` returns the file contents with the file's content type. Generated apps use the name `sample_app` / `SampleApp` — replace these with your app's actual names.

  ## Endpoints

  GET /versions — list all versions and their available app specs

  GET /compare/<source_app_spec>...<target_app_spec>/diff — unified diff between two versions
      → /compare/<source_app_spec>...<target_app_spec> (visual diff page for users)
  GET /compare/<source_app_spec>...<target_app_spec>/diff/manifest — normalized JSON change manifest
  Note: the ... separating source and target is three literal dots.

  GET /browse/<app_spec>/files.txt — list all files in a generated app
      → /browse/<app_spec> (file browser page for users)
  GET /browse/<app_spec>/raw/<path> — fetch a specific file from a generated app
      → /browse/<app_spec>/files/<path> (file view page for users)

  ## App specs

  An app spec is a version string optionally followed by a phx.new flag, separated by a space.
  Use the app specs exactly as listed in /versions.

  Note: spaces in app specs must be encoded as %20 in URLs.

  Examples:
    /browse/1.7.10/files.txt                          (default, no flag)
    /browse/1.7.10%20--umbrella/files.txt             (umbrella flag)
    /browse/1.7.10/raw/config/dev.exs                 (fetch a file, no flag)
    /browse/1.7.10%20--umbrella/raw/config/dev.exs    (fetch a file, umbrella flag)
    /compare/1.7.14%20--no-ecto...1.8.0%20--no-ecto/diff/manifest
                                                     (compare flagged specs; both spaces encoded)


  ## Upgrading a Phoenix app

  1. GET /versions — find available versions and supported variants
  2. GET /compare/<source_app_spec>...<target_app_spec>/diff/manifest — inspect the normalized file-level change inventory
  3. GET /compare/<source_app_spec>...<target_app_spec>/diff — get the full unified diff (use ?include=<path_prefix> to focus on specific files or directories)
  4. Apply the diff, replacing `sample_app`/`SampleApp` with your app's actual names

  The ?include= param is prefix-based and repeatable. For example:
    /compare/1.7.14...1.8.0/diff?include=mix.exs&include=config
  """

  def show(conn, _params) do
    conn
    |> put_resp_content_type("text/plain", nil)
    |> send_resp(200, @body)
  end
end
