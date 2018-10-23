defmodule PhxDiffWeb.PageController do
  use PhxDiffWeb, :controller

  alias PhxDiff.Diffs

  def index(conn, _params) do
    conn
    |> assign(:all_versions, Diffs.all_versions())
    |> assign(:source_version, Diffs.previous_release_version())
    |> assign(:target_version, Diffs.latest_version())
    |> render("index.html")
  end
end
