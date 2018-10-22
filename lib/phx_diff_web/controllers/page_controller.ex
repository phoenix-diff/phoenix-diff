defmodule PhxDiffWeb.PageController do
  use PhxDiffWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
