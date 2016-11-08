defmodule PhoenixDiff.Router do
  use PhoenixDiff.Web, :router

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

  scope "/", PhoenixDiff do
    pipe_through :browser # Use the default browser stack

    get "/", LandingPageController, :index
  end

  scope "/", PhoenixDiff do
    get "/diffs/:from/:to", DiffsController, :show

    get "/.well-known/acme-challenge/:id", WellKnownLocationsController, :acme_challenge
  end
end
