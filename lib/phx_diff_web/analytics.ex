defmodule PhxDiffWeb.Analytics do
  @moduledoc false

  import Plug.Conn

  @ga_tracking_id "UA-83682443-3"

  def fetch_analytics_config(conn, _opts) do
    config = %{
      enabled?: Application.get_env(:phx_diff, :render_tracking_scripts, false),
      ga_tracking_id: @ga_tracking_id
    }

    assign(conn, :analytics, config)
  end

  def fetch_honeybadger_config(conn, _opts) do
    config =
      for key <- [:api_key, :environment_name, :revision], into: %{} do
        {key, Honeybadger.get_env(key)}
      end

    assign(conn, :honeybadger, config)
  end
end
