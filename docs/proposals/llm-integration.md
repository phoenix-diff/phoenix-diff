# LLM Integration Proposal

This document proposes a plain-text, machine-readable API so LLMs can discover available Phoenix versions, retrieve upgrade diffs, and read individual generated files.

Status: partially implemented. `/llms.txt`, `/versions`, and `/browse/<app_spec>/raw/<path>` are shipped. The diff endpoints (`/compare/.../diff`, `/compare/.../diff/stat`) and file-listing endpoint (`/browse/.../files.txt`) remain proposals.

## Goals

1. Let an LLM autonomously upgrade a Phoenix application between any two versions.
2. Let an LLM inspect a generated Phoenix app at any version (e.g. to scaffold a new project or answer "what does a fresh 1.8.5 app look like?").
3. Keep the interface simple — plain text, cacheable, no auth.

## Proposed endpoints

### Discovery

#### `GET /llms.txt`

**Implemented.** A static plain-text discovery file following the [llms.txt](https://llmstxt.org) convention. No `Cache-Control` header is set (the proposal suggested a 24-hour cache).

The body only references the two currently implemented endpoints (`/versions` and `/browse/<app_spec>/raw/<path>`). It will be updated as additional endpoints ship.

Actual output:

```
# PhxDiff

PhxDiff generates diffs between Phoenix Framework versions so you can upgrade your app.

All endpoints return plain text. Generated apps use the name `sample_app` / `SampleApp` — replace these with your app's actual names.

## Endpoints

GET /versions — list all versions and their available app specs
GET /browse/<app_spec>/raw/<path> — fetch a specific file from a generated app

## App specs

An app spec is a version string optionally followed by a phx.new flag, separated by a space.
Use the app specs exactly as listed in /versions, URL-encoding spaces as %20.

Examples:
  /browse/1.7.10/raw/config/dev.exs          (no flag)
  /browse/1.7.10%20--umbrella/raw/config/dev.exs
```

Once the diff and file-listing endpoints ship, the body should be updated to include:

```
GET /compare/<source>...<target>/diff — unified diff between two versions
GET /compare/<source>...<target>/diff/stat — summary of changed files and line counts
GET /browse/<app_spec>/files.txt — list all files in a generated app
```

along with the "How to upgrade a Phoenix app" workflow and `?exclude=` option documentation.

### Versions

#### `GET /versions`

**Implemented.** Returns all known Phoenix versions and their supported variants. Plain text, one version per line. No `Cache-Control` header is set (cheap to assemble).

The format differs from the original proposal: variants are listed as full app spec strings (the exact value to use in a URL), not as a `default` keyword or bare flag. The default variant is listed as just the version number. The header comment example references `/browse/.../files.txt` which is not yet implemented.

Actual response format:

```
# Each line lists the app specifications available for that version.
# Use the app spec directly in the /browse endpoint (URL-encode spaces as %20).
# Example: /browse/1.8.5%20--no-ecto/raw/mix.exs

1.8.5: 1.8.5, 1.8.5 --binary-id, 1.8.5 --no-ecto, 1.8.5 --no-html, 1.8.5 --no-live, 1.8.5 --umbrella
1.8.4: 1.8.4, 1.8.4 --binary-id, 1.8.4 --no-ecto, 1.8.4 --no-html, 1.8.4 --no-live, 1.8.4 --umbrella
1.7.14: 1.7.14, 1.7.14 --binary-id, 1.7.14 --no-ecto, 1.7.14 --no-html, 1.7.14 --no-live, 1.7.14 --umbrella
...
1.5.11: 1.5.11 --live
1.4.17: 1.4.17
1.3.0: 1.3.0
```

Versions are listed in descending order (newest first).

### Diffs

#### `GET /compare/<source>...<target>/diff`

**Not yet implemented.**

Would return a raw unified diff (`text/plain`) between two generated Phoenix app versions. The diff would be generated via `git diff --no-index` with the histogram algorithm. Only the `diff` and `diff/stat` sub-paths are supported.

- `<source>` and `<target>` are URL-encoded app specifications (see below)
- `?exclude=<path_prefix>` — exclude repo-relative path prefixes from the diff; repeated params are combined
- Binary files appear as `Binary files a/<path> and b/<path> differ` with no content — use `/browse/<app_spec>/raw/<path>` to fetch the actual file
- Returns `200` with an empty body when source and target are identical
- Returns `404` with a plain `Not Found` body for unknown versions or invalid specs. Descriptive error messages (e.g. distinguishing "unknown version" from "unsupported variant") are a potential future enhancement.
- Response includes `Content-Disposition: inline; filename="<source>...<target>.diff"` for convenient browser downloads
- Cached for 24 hours on success, `no-store` on 404

Exclude semantics:

- Matching is case-sensitive and prefix-based on normalized repo-relative paths
- `?exclude=assets/vendor` excludes `assets/vendor/**`
- `?exclude=mix.exs` excludes only `mix.exs`
- Empty values are invalid
- Any exclude containing `.` or `..` path segments after normalization is invalid

Example response for `GET /compare/1.7.14...1.8.0/diff`:

```
diff --git a/mix.exs b/mix.exs
index 1234567..abcdefg 100644
--- a/mix.exs
+++ b/mix.exs
@@ -4,7 +4,7 @@ defmodule SampleApp.MixProject do
   def project do
     [
       app: :sample_app,
-      version: "0.1.0",
+      version: "1.0.0",
       elixir: "~> 1.14",
       elixirc_paths: elixirc_paths(Mix.env()),
       start_permanent: Mix.env() == :prod,
@@ -31,7 +31,7 @@ defmodule SampleApp.MixProject do
   defp deps do
     [
-      {:phoenix, "~> 1.7.14"},
+      {:phoenix, "~> 1.8.0"},
       {:phoenix_ecto, "~> 4.5"},
       ...
     ]
   end
diff --git a/config/config.exs b/config/config.exs
...
```

#### `GET /compare/<source>...<target>/diff/stat`

**Not yet implemented.**

Would return a `git diff --stat` summary of changed files and line counts. This lets an LLM survey the scope of a diff before fetching the full content or individual files.

Example response for `GET /compare/1.7.14...1.8.0/diff/stat`:

```
 mix.exs          | 4 ++--
 config/config.exs | 2 +-
 lib/sample_app_web/endpoint.ex | 3 ++-
 ...
 15 files changed, 42 insertions(+), 38 deletions(-)
```

### File access

#### `GET /browse/<app_spec>/files.txt`

**Not yet implemented.**

Would return a plain-text list of all file paths in a generated Phoenix app, one path per line. This lets an LLM discover what files exist before fetching specific ones.

Example response for `GET /browse/1.8.5/files.txt`:

```
.formatter.exs
.gitignore
README.md
assets/css/app.css
assets/js/app.js
assets/vendor/topbar.js
config/config.exs
config/dev.exs
config/prod.exs
config/runtime.exs
config/test.exs
lib/sample_app/application.ex
lib/sample_app/mailer.ex
lib/sample_app/repo.ex
lib/sample_app_web.ex
lib/sample_app_web/components/core_components.ex
lib/sample_app_web/components/layouts.ex
lib/sample_app_web/components/layouts/app.html.heex
lib/sample_app_web/components/layouts/root.html.heex
lib/sample_app_web/controllers/error_html.ex
lib/sample_app_web/controllers/error_json.ex
lib/sample_app_web/controllers/page_controller.ex
lib/sample_app_web/controllers/page_html.ex
lib/sample_app_web/controllers/page_html/home.html.heex
lib/sample_app_web/endpoint.ex
lib/sample_app_web/router.ex
lib/sample_app_web/telemetry.ex
mix.exs
mix.lock
priv/repo/migrations/.formatter.exs
priv/repo/seeds.exs
priv/static/favicon.ico
priv/static/robots.txt
test/sample_app_web/controllers/error_html_test.exs
test/sample_app_web/controllers/error_json_test.exs
test/sample_app_web/controllers/page_controller_test.exs
test/support/conn_case.ex
test/support/data_case.ex
test/test_helper.exs
```

#### `GET /browse/<app_spec>/raw/<path>`

**Implemented.** Returns the raw content of a single file from a generated Phoenix app. Sets the content type based on the file extension via `MIME.from_path/1`; files with an unknown extension (MIME type `application/octet-stream`) fall back to `text/plain`. Returns `404` for unknown app specs, invalid versions, or missing files. No `Cache-Control` header is set.

### App specification encoding

An app specification is a version string optionally followed by one `phx.new` flag in the initial proposal:

| App spec | Encoded |
|---|---|
| `1.8.5` (default) | `1.8.5` |
| `1.8.5 --binary-id` | `1.8.5%20--binary-id` |
| `1.8.5 --no-ecto` | `1.8.5%20--no-ecto` |

See `PhxDiffWeb.Params` for encoding/decoding logic.

The encoding format is intentionally space-delimited so it can remain forward-compatible with multiple flags later, once dynamic app generation exists.

## LLM workflows

### Upgrading a Phoenix app

Steps 3–4 require the diff endpoints which are not yet implemented.

1. `GET /llms.txt` — discover endpoints and capabilities
2. `GET /versions` — find available versions and supported variants
3. `GET /compare/<source>...<target>/diff/stat` — check the scope of changes _(not yet implemented)_
4. `GET /compare/<source>...<target>/diff` — get the full diff (use `?exclude=assets/vendor` if stat shows too many vendored changes) _(not yet implemented)_
5. Apply the diff, replacing `sample_app`/`SampleApp` with real app/module names

### Inspecting a generated app

Step 3 requires the file-listing endpoint which is not yet implemented. Individual files can already be fetched via step 4.

1. `GET /llms.txt` — discover endpoints and capabilities
2. `GET /versions` — find available versions and supported variants
3. `GET /browse/<app_spec>/files.txt` — list all files in the generated app _(not yet implemented)_
4. `GET /browse/<app_spec>/raw/<path>` — read individual files (**implemented**)

## Routing

The LLM endpoints share URL structure with the browser routes and are plain-text representations of the same resources:

| Browser (LiveView) | LLM (plain text) | Status |
|---|---|---|
| `GET /compare/:diff_spec` | `GET /compare/:diff_spec/diff` | not yet implemented |
| `GET /browse/:app_spec` | `GET /browse/:app_spec/files.txt` | not yet implemented |
| `GET /browse/:app_spec/files/*path` | `GET /browse/:app_spec/raw/*path` | **implemented** |
| — | `GET /versions` (LLM only) | **implemented** |
| — | `GET /llms.txt` (LLM only) | **implemented** |

This avoids duplicating URL hierarchy under a separate `/api/` prefix. The current router scope (no pipeline, so no browser session/CSRF middleware):

```elixir
scope "/", PhxDiffWeb do
  get "/llms.txt", LLMTextController, :show
  get "/versions", VersionController, :index
  get "/browse/:app_specification/raw/*path", RawFileController, :show
end
```

Target routing once all endpoints are implemented:

```elixir
scope "/", PhxDiffWeb do
  get "/llms.txt", LLMTextController, :show
  get "/versions", VersionController, :index
  get "/compare/:diff_specification/diff", DiffController, :show
  get "/compare/:diff_specification/diff/stat", DiffController, :stat
  get "/browse/:app_specification/files.txt", FileListController, :index
  get "/browse/:app_specification/raw/*path", RawFileController, :show
end
```

## Operational constraints

### Public URL required for `WebFetch`-based agents

Many LLM agents rely on `WebFetch`-style tools that reject localhost and other non-public addresses.

Under this proposal:

- Agents using `WebFetch` require a public HTTPS base URL
- Localhost-only access is out of scope for the LLM-facing API
- Local development should use a temporary public tunnel if remote agent access is needed
- Real agent usage should prefer a deployed preview or staging URL
