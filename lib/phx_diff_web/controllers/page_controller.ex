defmodule PhxDiffWeb.PageController do
  use PhxDiffWeb, :controller

  alias PhxDiff.Diffs

  def index(conn, params) do
    conn
    |> assign(:all_versions, Diffs.all_versions())
    |> assign(:source_version, Map.get(params, "source", Diffs.previous_release_version()))
    |> assign(:target_version, Map.get(params, "target", Diffs.latest_version()))
    |> render("index.html")
  end
end
