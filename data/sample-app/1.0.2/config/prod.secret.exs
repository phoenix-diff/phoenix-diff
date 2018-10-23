use Mix.Config

# In this file, we keep production configuration that
# you likely want to automate and keep it away from
# your version control system.
config :sample_app, SampleApp.Endpoint,
  secret_key_base: "aaaaaaaa"

# Configure your database
config :sample_app, SampleApp.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "sample_app_prod",
  pool_size: 20
