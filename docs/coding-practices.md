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

## Styling

- Tailwind CSS (v4) — utility-first, no custom CSS files unless necessary.
- Max line length: 120 characters (enforced by Credo).
