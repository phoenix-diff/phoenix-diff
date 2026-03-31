# LLM Integration Proposal

This document proposes a plain-text, machine-readable API so LLMs can discover available Phoenix versions, retrieve upgrade diffs, and read individual generated files.

Status: proposal only. The endpoint shapes and examples below describe a proposed LLM-facing API, not the currently shipped interface.

## Goals

1. Let an LLM autonomously upgrade a Phoenix application between any two versions.
2. Let an LLM inspect a generated Phoenix app at any version (e.g. to scaffold a new project or answer "what does a fresh 1.8.5 app look like?").
3. Keep the interface simple — plain text, cacheable, no auth.

## Proposed endpoints

### Discovery

#### `GET /llms.txt`

Under this proposal, `/llms.txt` would be a plain-text discovery file following the [llms.txt](https://llmstxt.org) convention. It would be dynamically generated from live version data and cached for 24 hours (`Cache-Control: public, max-age=86400`).

Illustrative output:

```
# PhxDiff

PhxDiff generates diffs between Phoenix Framework versions so you can upgrade your app.

All endpoints return plain text. Generated apps use the name `sample_app` / `SampleApp` — replace these with your app's actual names.

## How to upgrade a Phoenix app

1. GET /versions — find your current and target versions
2. If the app was generated with a phx.new flag (e.g. --no-ecto), use that variant in both source and target so the diff matches your app's structure
3. GET /compare/<current>...<target>/diff/stat — check the scope of changes
4. GET /compare/<current>...<target>/diff — get the full diff (if the stat shows too many changes in vendored paths like assets/vendor, use ?exclude=assets/vendor to skip them)
5. Apply the diff to your app, replacing `sample_app` with your app name and `SampleApp` with your module name

## Endpoints

GET /versions — list all versions and their supported variants
GET /compare/<source>...<target>/diff — unified diff between two versions
GET /compare/<source>...<target>/diff/stat — summary of changed files and line counts
GET /browse/<app_spec>/files.txt — list all files in a generated app
GET /browse/<app_spec>/raw/<path> — fetch a specific file

Options:
- ?exclude=<path_prefix> — exclude repo-relative path prefixes from the diff. Can be repeated, e.g. ?exclude=assets/vendor&exclude=priv/static

## Variants

Initial proposal: support `default` plus at most one `phx.new` flag at a time, matching the currently generated sample-app variants.

The app specification encoding should remain future-compatible with multiple flags once dynamic app generation exists.

GET /compare/1.7.14...1.8.5%20--no-ecto/diff
GET /browse/1.8.5%20--umbrella/files.txt
```

### Versions

#### `GET /versions`

Would return all known Phoenix versions and their supported variants (`default` plus any single-flag variants available for that version). Plain text, one version per line. Not cached (cheap to assemble). Every listed version has at least one variant; `default` is present unless only non-default variants are available for that version (e.g. `1.5.11: --live`).

Example response:

```
# Each version lists the variants currently available for that version.
# Each app specification uses at most one phx.new flag.
# Example: /browse/1.8.5%20--no-ecto/files.txt

1.8.5: default, --binary-id, --no-ecto, --no-html, --no-live, --umbrella
1.8.4: default, --binary-id, --no-ecto, --no-html, --no-live, --umbrella
1.7.14: default, --binary-id, --no-ecto, --no-html, --no-live, --umbrella
...
1.6.15: default, --binary-id, --no-ecto, --no-html, --no-live, --umbrella
1.5.11: --live
1.4.17: default
1.3.0: default
```

### Diffs

#### `GET /compare/<source>...<target>/diff`

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

Would return the raw content of a single file from a generated Phoenix app. It would set the content type based on the file extension and return `404` for unknown app specs or missing files.

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

1. `GET /llms.txt` — discover endpoints and capabilities
2. `GET /versions` — find available versions and supported variants
3. `GET /compare/<source>...<target>/diff/stat` — check the scope of changes
4. `GET /compare/<source>...<target>/diff` — get the full diff (use `?exclude=assets/vendor` if stat shows too many vendored changes)
5. Apply the diff, replacing `sample_app`/`SampleApp` with real app/module names

### Inspecting a generated app

1. `GET /llms.txt` — discover endpoints and capabilities
2. `GET /versions` — find available versions and supported variants
3. `GET /browse/<app_spec>/files.txt` — list all files in the generated app
4. `GET /browse/<app_spec>/raw/<path>` — read individual files

## Proposed routing

The LLM endpoints would share URL structure with the browser routes. They would be plain-text representations of the same resources:

| Browser (LiveView) | LLM (plain text) |
|---|---|
| `GET /compare/:diff_spec` | `GET /compare/:diff_spec/diff` |
| `GET /browse/:app_spec` | `GET /browse/:app_spec/files.txt` |
| `GET /browse/:app_spec/files/*path` | `GET /browse/:app_spec/raw/*path` |
| — | `GET /versions` (LLM only) |
| — | `GET /llms.txt` (LLM only) |

This would avoid duplicating URL hierarchy under a separate `/api/` prefix. Shared middleware (e.g. CORS) could be applied via a pipeline on the scope without changing paths:

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
