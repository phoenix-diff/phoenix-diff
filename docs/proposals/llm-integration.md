# LLM Integration Proposal

This document proposes a machine-readable, cacheable HTTP API so LLMs can discover available Phoenix versions, retrieve upgrade diffs, and read individual generated files.

Status: partially implemented. `/llms.txt`, `/versions`, `/browse/<app_spec>/raw/<path>`, and `/browse/<app_spec>/files.txt` are shipped. The diff endpoints (`/compare/.../diff`, `/compare/.../diff/manifest`) remain proposals.

## Goals

1. Let an LLM autonomously upgrade a Phoenix application between any two versions.
2. Let an LLM inspect a generated Phoenix app at any version (e.g. to scaffold a new project or answer "what does a fresh 1.8.5 app look like?").
3. Keep the interface simple — machine-readable, cacheable, no auth.

Response formats are chosen per resource: listings and unified diffs use `text/plain`, raw file reads use the file's content type, and `/compare/<source>...<target>/diff/manifest` uses `application/json`.

## Proposed endpoints

### Discovery

#### `GET /llms.txt`

**Implemented.** A static plain-text discovery file following the [llms.txt](https://llmstxt.org) convention. No `Cache-Control` header is set (the proposal suggested a 24-hour cache).

The current body references only the currently implemented endpoints. Once the diff endpoints ship, the body should be updated to something like:

```
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
Use the app specs exactly as listed in /versions, URL-encoding spaces as %20.

Examples:
  /browse/1.7.10/raw/config/dev.exs          (no flag)
  /browse/1.7.10%20--umbrella/raw/config/dev.exs
```

### Versions

#### `GET /versions`

**Implemented.** Returns all known Phoenix versions and their supported variants. Plain text, one version per line. No `Cache-Control` header is set (cheap to assemble).

The format differs from the original proposal: variants are listed as full app spec strings (the exact value to use in a URL), not as a `default` keyword or bare flag. The default variant is listed as just the version number.

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

Would return a raw unified diff (`text/plain`) between two generated Phoenix app versions. The diff would be generated via `git diff --no-index` with the histogram algorithm.

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

#### `GET /compare/<source>...<target>/diff/manifest`

**Not yet implemented.**

Would return a normalized JSON manifest of file-level changes. This endpoint is intended as the LLM-first overview format: much smaller and more structured than the full unified diff. It is advisory only; `/diff` remains the authoritative patch representation.

The manifest should be derived from Git's machine-readable diff metadata, but the response format should be owned by PhxDiff rather than exposing raw Git output directly. That keeps the API stable and removes presentation-oriented parsing work from the client.

Suggested Git command:

```bash
git -c core.quotepath=false \
  diff --no-index -M --numstat -z --diff-algorithm=histogram -- "$source_path" "$target_path"
```

`-M` uses Git's default rename-detection threshold (approximately 50% similarity). This threshold is not configurable via the API. If the threshold is tuned in a future release, some entries may shift between `renamed` and separate `deleted`/`added` pairs.

This emits repeated NUL-delimited triples of:

1. `<added>\t<deleted>\t`
2. `<old_path>`
3. `<new_path>`

After stripping the source and target directory prefixes, the output shape is:

```text
54\t0\t | assets/css/app.scss | assets/css/app.scss
0\t63\t | assets/js/socket.js | /dev/null
39\t0\t | /dev/null | lib/sample_app_web/live/page_live.ex
10\t0\t | lib/sample_app_web/templates/page/index.html.eex | lib/sample_app_web/live/page_live.html.leex
-\t-\t | priv/static/favicon.ico | priv/static/favicon.ico
```

Interpretation rules:

- `old_path == /dev/null` means `added`
- `new_path == /dev/null` means `deleted`
- `old_path != new_path` with neither side `/dev/null` means `renamed`
- `old_path == new_path` means `modified`
- `added == "-"` and `deleted == "-"` means a binary change, so `binary: true` should be set and line counts omitted

Suggested response format:

```json
{
  "source": { "version": "1.7.14", "flags": ["--no-ecto"] },
  "target": { "version": "1.8.0", "flags": ["--no-ecto"] },
  "total_files": 6,
  "total_added": 67,
  "total_deleted": 12,
  "files": [
    { "path": "gone.txt", "status": "deleted", "added": 0, "deleted": 8 },
    { "path": "lib/sample_app_web/components/layouts.ex", "status": "renamed", "old_path": "lib/sample_app_web/views/layout_view.ex", "added": 5, "deleted": 3 },
    { "path": "mix.exs", "status": "modified", "added": 1, "deleted": 1 },
    { "path": "new.txt", "status": "renamed", "old_path": "old.txt" },
    { "path": "new_only.txt", "status": "added", "added": 12, "deleted": 0 },
    { "path": "priv/static/favicon.ico", "status": "modified", "binary": true }
  ]
}
```

Field semantics:

- `source` and `target` are objects that echo the resolved app specifications in structured form, so the response is self-describing even when cached or passed between tools. Each contains:
  - `version` (string, always present) — the Phoenix version (e.g. `"1.8.0"`)
  - `flags` (array of strings, always present) — the `phx.new` flags for that app spec, or `[]` when there are none
  - Additional fields may be added in the future (e.g. post-generation commands) as app specs gain new dimensions
- `total_files` is the number of entries in `files`
- `total_added` and `total_deleted` are the sums of `added` and `deleted` across all entries in `files` (binary entries contribute 0). These let an LLM gauge upgrade size at a glance without iterating the array.
- `files` is ordered alphabetically by `path`. This provides deterministic ordering independent of Git internals.
- `path` is the canonical target-side path for the entry. For `modified` and `added`, it is the file's current path in the target app. For `deleted`, it is the path that existed in the source app and no longer exists in the target. For `renamed`, it is the destination path and `old_path` is the source path.
- `status` is one of `modified`, `added`, `deleted`, or `renamed`. This v1 manifest intentionally models only content/path changes relevant to generated Phoenix apps; mode-only changes and type changes are out of scope. Clients should ignore unknown object fields and tolerate unknown future `status` values.
- `old_path` is present only for `renamed` entries
- `added` and `deleted` are present on `renamed` entries when the content also changed (rename-with-modification); omitted when only the path changed
- `added` and `deleted` should be included for `modified`, `added`, and `deleted` text files. For `added` entries `deleted` is always 0, and for `deleted` entries `added` is always 0; both fields are still included for uniformity so clients can sum line counts without branching on status. For binary entries, textual line counts are not meaningful and these fields should be omitted.
- `binary: true` marks entries where the file content is binary. It may appear on `modified`, `added`, `deleted`, or `renamed` entries.

Why add a manifest endpoint:

- Git's human-oriented `--stat` output includes spacing and ASCII bars that are unnecessary for LLMs
- Raw `--numstat -z` output is machine-readable, but still needs PhxDiff to normalize path pairs into explicit `modified`, `added`, `deleted`, and `renamed` entries
- A JSON manifest gives the model an advisory file inventory before it fetches `/diff` or individual files
- The manifest can encode binary changes explicitly instead of relying on Git-specific placeholders

Behavior notes:

- This endpoint does not support `?exclude=<path_prefix>`; it always returns the full file-level change inventory for the selected comparison. Clients may use it to decide which `/diff` request to fetch next, but should treat the manifest as advisory rather than expecting totals to match a later filtered diff.
- If source and target are identical, return `200` with an empty JSON manifest: `{ "source": { "version": "<version>", "flags": [] }, "target": { "version": "<version>", "flags": [] }, "total_files": 0, "total_added": 0, "total_deleted": 0, "files": [] }`. (The `/diff` endpoint returns an empty body for the same case; the manifest always returns valid JSON so clients need not special-case the response.)
- If Git does not detect a rename, emit separate `deleted` and `added` entries rather than inferring one
- Rename detection uses Git's default `-M` threshold (see above) rather than a PhxDiff-specific inference pass.
- Response should use `application/json`
- No `Content-Disposition` header (JSON is rendered inline by browsers; the diff endpoint uses it because `.diff` files trigger downloads)
- Cached for 24 hours on success, `no-store` on 404

### File access

#### `GET /browse/<app_spec>/files.txt`

**Implemented.** Returns a plain-text list of all file paths in a generated Phoenix app, one path per line. This lets an LLM discover what files exist before fetching specific ones via `/raw/<path>`. Returns `404` for unknown app specs or invalid versions. Cached for 24 hours on success.

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
3. `GET /compare/<source>...<target>/diff/manifest` — inspect the normalized file-level change inventory _(not yet implemented)_
4. `GET /compare/<source>...<target>/diff` — get the full diff for the files that matter (use `?exclude=assets/vendor` if the manifest shows too many vendored changes) _(not yet implemented)_
5. Apply the diff, replacing `sample_app`/`SampleApp` with real app/module names

### Inspecting a generated app

1. `GET /llms.txt` — discover endpoints and capabilities
2. `GET /versions` — find available versions and supported variants
3. `GET /browse/<app_spec>/files.txt` — list all files in the generated app
4. `GET /browse/<app_spec>/raw/<path>` — read individual files

## Routing

The LLM endpoints share URL structure with the browser routes and are machine-readable representations of the same resources:

| Browser (LiveView) | LLM (machine-readable) | Status |
|---|---|---|
| `GET /compare/:diff_spec` | `GET /compare/:diff_spec/diff` | not yet implemented |
| — | `GET /compare/:diff_spec/diff/manifest` | not yet implemented |
| `GET /browse/:app_spec` | `GET /browse/:app_spec/files.txt` | **implemented** |
| `GET /browse/:app_spec/files/*path` | `GET /browse/:app_spec/raw/*path` | **implemented** |
| — | `GET /versions` (LLM only) | **implemented** |
| — | `GET /llms.txt` (LLM only) | **implemented** |

This avoids duplicating URL hierarchy under a separate `/api/` prefix. The current router scope (no pipeline, so no browser session/CSRF middleware):

```elixir
scope "/", PhxDiffWeb do
  get "/llms.txt", LLMTextController, :show
  get "/versions", VersionController, :index
  get "/browse/:app_specification/files.txt", FileListController, :index
  get "/browse/:app_specification/raw/*path", RawFileController, :show
end
```

Target routing once all endpoints are implemented:

```elixir
scope "/", PhxDiffWeb do
  get "/llms.txt", LLMTextController, :show
  get "/versions", VersionController, :index
  get "/compare/:diff_specification/diff", DiffController, :show
  get "/compare/:diff_specification/diff/manifest", DiffController, :manifest
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
