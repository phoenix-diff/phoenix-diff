defmodule PhoenixDiff.LandingPageController do
  use PhoenixDiff.Web, :controller

  alias PhoenixDiff.Diff

  def index(conn, _params) do
    available_versions = Diff.available_versions

    conn
    |> assign(:available_versions, available_versions)
    |> assign(:latest_version, available_versions |> List.last)
    |> assign(:previous_version, available_versions |> Enum.at(-3))
    |> render("index.html")
  end
end
