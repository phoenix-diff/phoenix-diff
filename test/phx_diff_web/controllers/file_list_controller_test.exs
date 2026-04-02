defmodule PhxDiffWeb.FileListControllerTest do
  use PhxDiffWeb.ConnCase, async: true

  describe "GET /browse/:app_specification/files.txt" do
    test "returns 200 with text/plain file list", %{conn: conn} do
      conn = get(conn, ~p"/browse/1.7.1/files.txt")

      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["text/plain"]
      assert conn.resp_body =~ "mix.exs\n"
      assert conn.resp_body =~ ".gitignore\n"
      assert conn.resp_body =~ ".formatter.exs\n"
      lines = String.split(conn.resp_body, "\n", trim: true)
      assert length(lines) > 0
      assert String.ends_with?(conn.resp_body, "\n")
    end

    test "works with non-default app spec variant", %{conn: conn} do
      conn = get(conn, ~p"/browse/1.5.0 --live/files.txt")

      assert conn.status == 200
      assert conn.resp_body =~ "mix.exs\n"
    end

    test "returns 404 for unknown or malformed app spec", %{conn: conn} do
      assert_error_sent(404, fn -> get(conn, ~p"/browse/0.0.0/files.txt") end)
      assert_error_sent(404, fn -> get(conn, ~p"/browse/not-a-version/files.txt") end)
    end
  end
end
