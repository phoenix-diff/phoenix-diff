defmodule PhoenixDiff.LandingPageControllerTest do
  use PhoenixDiff.ConnCase

  test "GET /", %{conn: conn} do
    conn = get conn, "/"
    assert html_response(conn, 200) =~ "PhoenixDiff"
  end
end
