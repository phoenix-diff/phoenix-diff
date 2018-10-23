defmodule SampleAppWeb.PageController do
  use SampleAppWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
