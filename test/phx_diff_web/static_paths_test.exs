defmodule PhxDiffWeb.StaticPathsTest do
  use PhxDiffWeb.ConnCase, async: true

  test "GET favicon paths", %{conn: conn} do
    assert conn
           |> get(~p"/favicon.ico")
           |> response(200)
  end

  test "GET an unknown path", %{conn: conn} do
    assert_error_sent(404, fn ->
      get(conn, "/unknown")
    end)
  end
end
