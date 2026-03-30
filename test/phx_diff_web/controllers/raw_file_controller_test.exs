defmodule PhxDiffWeb.RawFileControllerTest do
  use PhxDiffWeb.ConnCase, async: true

  describe "GET /browse/:app_specification/raw/*path" do
    test "returns text file content with correct content type", %{conn: conn} do
      conn = get(conn, ~p"/browse/1.7.1/raw/mix.exs")

      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["text/plain"]
      assert conn.resp_body =~ "defmodule"
    end

    test "returns nested file content", %{conn: conn} do
      conn = get(conn, ~p"/browse/1.7.1/raw/config/config.exs")

      assert conn.status == 200
      assert conn.resp_body =~ "import Config"
    end

    test "returns binary file with appropriate content type", %{conn: conn} do
      conn = get(conn, ~p"/browse/1.7.1/raw/priv/static/favicon.ico")

      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["image/vnd.microsoft.icon"]
    end

    test "returns 404 for nonexistent file", %{conn: conn} do
      assert_error_sent(404, fn ->
        get(conn, ~p"/browse/1.7.1/raw/no/such/file.ex")
      end)
    end

    test "returns 404 for invalid version", %{conn: conn} do
      assert_error_sent(404, fn ->
        get(conn, ~p"/browse/0.0.0/raw/mix.exs")
      end)
    end

    test "returns 404 for malformed app spec", %{conn: conn} do
      assert_error_sent(404, fn ->
        get(conn, ~p"/browse/not-a-version/raw/mix.exs")
      end)
    end

    test "returns 404 for path traversal attempts", %{conn: conn} do
      assert_error_sent(404, fn ->
        get(conn, ~p"/browse/1.7.1/raw/lib/..%2F..%2F..%2Fetc%2Fpasswd")
      end)
    end

    test "works with non-default app spec variant", %{conn: conn} do
      conn = get(conn, ~p"/browse/1.5.0 --live/raw/mix.exs")

      assert conn.status == 200
      assert conn.resp_body =~ "defmodule"
    end
  end
end
