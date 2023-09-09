defmodule PhxDiffWeb.PageController do
  use PhxDiffWeb, :controller

  def index(conn, _params) do
    redirect(conn, to: ~p"/compare")
  end
end
