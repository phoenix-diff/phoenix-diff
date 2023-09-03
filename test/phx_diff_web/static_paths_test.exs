defmodule PhxDiffWeb.StaticPathsTest do
  use PhxDiffWeb.ConnCase, async: true

  test "GET favicon paths", %{conn: conn} do
    assert conn
           |> get(~p"/favicon.ico")
           |> response(200)
  end

  test "GET an unknown path", %{conn: conn} do
    assert conn
           |> get("/unknown")
           |> response(404)
  end
end
