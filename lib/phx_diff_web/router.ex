defmodule PhxDiffWeb.Router do
  use PhxDiffWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PhxDiffWeb do
    pipe_through :browser

    get "/", PageController, :index
    get "/diffs", DiffController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", PhxDiffWeb do
  #   pipe_through :api
  # end
end
