# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :phx_diff, PhxDiffWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "yZ51VROLXAgAiopHqa3JgxK2SDFp9BymmYjkVs1EjKhsJUbPJeg6WZIIqyp0C5Lk",
  render_errors: [view: PhxDiffWeb.ErrorView, accepts: ~w(html json)],
  pubsub_server: PhxDiff.PubSub,
  live_view: [signing_salt: "NpCfQvr9hr3z/LRwF8WZL5LmKP0wC9e3"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :honeybadger,
  environment_name: System.get_env("HONEYBADGER_ENV_NAME", to_string(Mix.env()))

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
