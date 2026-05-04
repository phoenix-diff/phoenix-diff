# Coding Practices

## Project Overview

Phoenix Diff shows diffs between generated Phoenix app versions to help developers upgrade. It has no database — data comes from pre-generated files on disk.

## Layered API Pattern

Each namespace layer follows the same structure:

- The parent module is the public face of that layer: it contains business logic and delegates to child modules when necessary.
- Child modules are internal (`@moduledoc false`) and invisible outside the layer, unless they are public structs belonging to a cohesive namespace (e.g. `PhxDiff.Diff.Patch`).
- Public structs belong at or near the layer's namespace root (e.g. `PhxDiff.DiffManifest`, not `PhxDiff.Diffs.DiffManifest`).
- Flow is strictly top-down: parents call children, never the reverse.

## Code Organization

- **`PhxDiff`** — core business logic (diff computation, app specs, file access)
- **`PhxDiffWeb`** — web layer (controllers, LiveViews, components, routing)
- Module boundaries are enforced by the [Boundary](https://hex.pm/packages/boundary) library. Respect `deps:` and `exports:` declarations on each module.
- Mix tasks use flat dot-separated filenames (e.g. `phx_diff.s3.seed.ex`) rather than nested directories, matching `Mix.Task` module names directly.

## Quality Gates

All of these must pass before merging (run via `mix ci`):

```
compile --warnings-as-errors
format --check-formatted
test --raise --all-warnings --warnings-as-errors
credo --strict --all
dialyzer
```

## Elixir Conventions

- Add `@spec` to every public function.
- Annotate LiveView/Plug callbacks with `@impl true`.
- Use `with` for multi-step error handling; avoid deeply nested `case`.
- Return `{:ok, value}` / `{:error, reason}` for fallible operations.
- Name boolean functions with a `?` suffix; bang functions with `!`.
- Use singular names for individual records, plural names for collections, and avoid names that could mean either.
- For keyword-list options, define a singular option tuple type, e.g.
  `@type put_object_opt :: {:content_type, String.t()} | {:if_none_match, String.t()}`,
  and reference lists inline in specs as `[put_object_opt()]` rather than defining a separate list alias.

## Configuration

- Access application environment values through the config adapter layer, not directly from feature modules.
- Core modules should call `PhxDiff.Config`; web modules should call `PhxDiffWeb.Config`.
- Read OS environment variables in `config/runtime.exs`, write them into the application environment, then expose them through the config module.
- Put application environment reads and default config lookups in the matching `DefaultAdapter` module.
- Store default application config values in `config/config.exs` instead of hard-coding fallback values at call sites.
- Add new adapter callbacks when feature code needs a new configurable value so tests can swap config with Mox.
- Avoid runtime config side effects in test environment: wrap config that reads files, environment variables, or makes network calls in `if config_env() != :test do ... end` blocks in `config/runtime.exs`. Tests run in the `:test` environment and should not depend on external resources.
- To stub core config in a test, import Mox, use `PhxDiff.MockedConfigCase` when the case template does not already include it, and stub the mock adapter:

```elixir
use ExUnit.Case, async: true
use PhxDiff.MockedConfigCase

import Mox

test "uses a custom app repo path" do
  stub(PhxDiff.Config.Mock, :app_repo_path, fn -> "/tmp/sample-apps" end)

  assert PhxDiff.Config.app_repo_path() == "/tmp/sample-apps"
end
```

## Routing

Use verified route sigils — never build URL strings manually:

```elixir
~p"/compare/#{diff_spec}"
```

## Testing

- Test from the outermost boundaries of the application: controller and LiveView tests for the web layer, and simulators (e.g. from the `sims` package) for external services. Avoid testing internal modules directly when an outer boundary test covers the same behaviour.
- Default to `async: true` unless the test requires shared state.
- Use `PhxDiffWeb.ConnCase` for HTTP tests, `Phoenix.LiveViewTest` for LiveViews.
- Avoid mocks unless necessary to enable `async: true` — for example, when a test needs to change global config, use `Mox` to swap the adapter per-process. Set up mocks in `test/support/mocked_config_case.ex`.
- Use `Floki` for HTML assertions (test-only dependency).
- Create test data in the tests that use it rather than in shared setup blocks, so each test only generates the data it needs.

## Styling

- Tailwind CSS (v4) — utility-first, no custom CSS files unless necessary.
- Max line length: 120 characters (enforced by Credo).
