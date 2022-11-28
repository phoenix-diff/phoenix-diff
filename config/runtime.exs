import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/phx_diff start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :phx_diff, PhxDiffWeb.Endpoint, server: true
end

if config_env() == :dev && System.get_env("ALLOW_EXTERNAL_ACCESS") == "true" do
  # Allow access beyond localhost
  config :phx_diff, PhxDiffWeb.Endpoint, http: [ip: {0, 0, 0, 0}, port: 4000]
end

if config_env() == :prod do
  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  # Optional config settings for the asset host
  static_url =
    for {key, env_var} <- [scheme: "ASSET_SCHEME", host: "ASSET_HOST", port: "ASSET_PORT"],
        env_val = System.get_env(env_var),
        do: {key, env_val}

  if Enum.any?(static_url) do
    config :phx_diff, PhxDiffWeb.Endpoint, static_url: static_url
  end

  # Configure the allowed origins
  check_origin =
    case System.get_env("ALLOWED_ORIGINS", "") |> String.split() do
      [_ | _] = origins -> origins
      _ -> true
    end

  config :phx_diff, PhxDiffWeb.Endpoint,
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: String.to_integer(System.get_env("PORT") || "4000")
    ],
    url: [
      scheme: System.get_env("URL_SCHEME", "https"),
      host: System.get_env("URL_HOST", "www.phoenixdiff.org"),
      port: String.to_integer(System.get_env("URL_PORT", "443"))
    ],
    check_origin: check_origin,
    secret_key_base: secret_key_base

  # ## Configuring the mailer
  #
  # In production you need to configure the mailer to use a different adapter.
  # Also, you may need to configure the Swoosh API client of your choice if you
  # are not using SMTP. Here is an example of the configuration:
  #
  #     config :phx_diff, PhxDiff.Mailer,
  #       adapter: Swoosh.Adapters.Mailgun,
  #       api_key: System.get_env("MAILGUN_API_KEY"),
  #       domain: System.get_env("MAILGUN_DOMAIN")
  #
  # For this example you need include a HTTP client required by Swoosh API client.
  # Swoosh supports Hackney and Finch out of the box:
  #
  #     config :swoosh, :api_client, Swoosh.ApiClient.Hackney
  #
  # See https://hexdocs.pm/swoosh/Swoosh.html#module-installation for details.
end

# Enables website analytics tracking scripts
if System.get_env("RENDER_TRACKING_SCRIPTS") == "true" do
  config :phx_diff, render_tracking_scripts: true
end

git_sha =
  with {:ok, "ref: " <> contents} <- File.read(".git/HEAD"),
       path = String.trim(contents),
       {:ok, sha} <- File.read(".git/#{path}") do
    String.trim(sha)
  else
    _ -> nil
  end

# Set the honeybadger environment name for all envs
config :honeybadger,
  environment_name: System.get_env("HONEYBADGER_ENV_NAME", to_string(config_env())),
  revision: git_sha

# OpenTelemetry configuration
config :opentelemetry, :resource,
  service: %{
    version: git_sha
  }

case System.fetch_env("OTEL_EXPORTER") do
  {:ok, "stdout"} ->
    config :opentelemetry, :processors,
      otel_batch_processor: %{
        exporter: {:otel_exporter_stdout, []}
      }

  {:ok, "honeycomb"} ->
    config :opentelemetry, :processors,
      otel_batch_processor: %{
        exporter:
          {:opentelemetry_exporter,
           %{
             endpoints: ["https://api.honeycomb.io:443"],
             headers: [
               {"x-honeycomb-team", System.fetch_env!("OTEL_HONEYCOMB_API_KEY")},
               {"x-honeycomb-dataset", System.fetch_env!("OTEL_HONEYCOMB_DATASET")}
             ]
           }}
      }

  {:ok, "signoz-local"} ->
    config :opentelemetry, :processors,
      otel_batch_processor: %{
        exporter:
          {:opentelemetry_exporter,
           %{
             endpoints: ["http://localhost:4318"]
           }}
      }

  :error ->
    # Disabled by default
    config :opentelemetry, traces_exporter: :none
end
