defmodule PhoenixDiff.LandingPageControllerTest do
  use PhoenixDiff.ConnCase

  test "GET /", %{conn: conn} do
    conn = get conn, "/"

    assert html_response(conn, 200) =~ "PhoenixDiff"

    assert conn.assigns.available_versions |> is_list
    assert conn.assigns.available_versions |> length >= 14

    assert conn.assigns.previous_version == "1.2.1"
    assert conn.assigns.latest_version == "1.3.0-rc.0"
  end
end
