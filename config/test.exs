import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :phx_diff, PhxDiffWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "yZ51VROLXAgAiopHqa3JgxK2SDFp9BymmYjkVs1EjKhsJUbPJeg6WZIIqyp0C5Lk",
  server: false

# Print only warnings and errors during test
config :logger, level: :debug

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

config :opentelemetry,
  tracer: :otel_tracer_default,
  processors: [
    otel_batch_processor: %{
      scheduled_delay_ms: 1
    }
  ]
