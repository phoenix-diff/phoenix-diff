defmodule PhxDiffWeb.Router do
  use PhxDiffWeb, :router
  use Honeybadger.Plug

  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {PhxDiffWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_honeybadger_config
    plug :fetch_analytics_config
    plug :put_current_path
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :require_admin do
    plug :admin_basic_auth
  end

  scope "/", PhxDiffWeb do
    get "/llms.txt", LLMTextController, :show
    get "/versions", VersionController, :index
    get "/browse/:app_specification/files.txt", FileListController, :index
    get "/browse/:app_specification/raw/*path", RawFileController, :show
  end

  scope "/", PhxDiffWeb do
    pipe_through :browser

    get "/", PageController, :index
    get "/compare", PageController, :compare
    live "/compare/:diff_specification", CompareLive, :compare

    get "/browse", PageController, :browse
    live "/browse/:app_specification/files/*path", BrowseLive, :file
    live "/browse/:app_specification", BrowseLive, :browse
  end

  scope "/" do
    pipe_through [:browser, :require_admin]

    live_dashboard "/dashboard",
      metrics: PhxDiffWeb.Telemetry,
      ecto_repos: []
  end

  # Other scopes may use custom stacks.
  # scope "/api", PhxDiffWeb do
  #   pipe_through :api
  # end

  defp put_current_path(conn, _opts) do
    assign(conn, :current_path, conn.request_path)
  end

  defp admin_basic_auth(conn, _opts) do
    credential = PhxDiffWeb.Config.admin_dashboard_credentials()

    Plug.BasicAuth.basic_auth(conn,
      username: credential.username,
      password: credential.password
    )
  end
end
