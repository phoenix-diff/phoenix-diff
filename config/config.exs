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
  pubsub_server: PhxDiff.PubSub

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :phoenix, :template_engines,
  slim: PhoenixSlime.Engine,
  slime: PhoenixSlime.Engine

config :phoenix_slime, :use_slim_extension, true

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
