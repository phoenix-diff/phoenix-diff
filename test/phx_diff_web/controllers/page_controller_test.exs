defmodule PhxDiffWeb.PageControllerTest do
  use PhxDiffWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "See the changes needed to upgrade"
  end
end
