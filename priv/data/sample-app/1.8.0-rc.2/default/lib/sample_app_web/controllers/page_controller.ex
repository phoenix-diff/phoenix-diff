defmodule SampleAppWeb.PageController do
  use SampleAppWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
