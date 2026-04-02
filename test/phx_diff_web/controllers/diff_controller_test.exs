defmodule PhxDiffWeb.DiffControllerTest do
  use PhxDiffWeb.ConnCase, async: true

  describe "GET /compare/:diff_specification/diff" do
    test "returns 200 with text/plain unified diff and cache headers", %{conn: conn} do
      conn = get(conn, ~p"/compare/1.7.1...1.7.14/diff")

      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["text/plain"]
      assert get_resp_header(conn, "cache-control") == ["public, max-age=86400"]
      assert conn.resp_body =~ "diff --git"
      assert conn.resp_body =~ "mix.exs"
    end

    test "returns Content-Disposition header with filename", %{conn: conn} do
      conn = get(conn, ~p"/compare/1.7.1...1.7.14/diff")

      assert [disposition] = get_resp_header(conn, "content-disposition")
      assert disposition =~ ~r/^inline; filename="/
      assert disposition =~ "1.7.1...1.7.14.diff"
    end

    test "returns 200 with empty body for identical versions", %{conn: conn} do
      conn = get(conn, ~p"/compare/1.7.1...1.7.1/diff")

      assert conn.status == 200
      assert conn.resp_body == ""
    end

    test "works with non-default app spec variant", %{conn: conn} do
      conn = get(conn, ~p"/compare/1.5.0 --live...1.5.1 --live/diff")

      assert conn.status == 200
    end

    test "returns 404 for unknown version without public cache headers", %{conn: conn} do
      {_status, headers, _body} =
        assert_error_sent(404, fn -> get(conn, ~p"/compare/0.0.0...1.7.14/diff") end)

      assert {"cache-control", "max-age=0, private, must-revalidate"} in headers
    end

    test "returns 404 for malformed diff spec", %{conn: conn} do
      assert_error_sent(404, fn -> get(conn, ~p"/compare/not-a-version/diff") end)
    end

    test "excludes files matching the ?exclude= prefix", %{conn: conn} do
      conn = get(conn, ~p"/compare/1.7.1...1.7.14/diff?exclude=assets")

      assert conn.status == 200
      refute conn.resp_body =~ "diff --git a/assets/"
    end

    test "supports multiple ?exclude[]= params", %{conn: conn} do
      conn = get(conn, "/compare/1.7.1...1.7.14/diff?exclude[]=assets&exclude[]=mix.lock")

      assert conn.status == 200
      refute conn.resp_body =~ "diff --git a/assets/"
      refute conn.resp_body =~ "diff --git a/mix.lock "
    end

    test "returns 400 for empty ?exclude= value", %{conn: conn} do
      assert_error_sent(400, fn -> get(conn, "/compare/1.7.1...1.7.14/diff?exclude=") end)
    end

    test "returns 400 for ?exclude= value with .. segment", %{conn: conn} do
      assert_error_sent(400, fn ->
        get(conn, "/compare/1.7.1...1.7.14/diff?exclude=assets%2F..%2Fconfig")
      end)
    end

    test "returns 400 for ?exclude= value with . segment", %{conn: conn} do
      assert_error_sent(400, fn ->
        get(conn, "/compare/1.7.1...1.7.14/diff?exclude=assets%2F.")
      end)
    end
  end

  describe "GET /compare/:diff_specification/diff/stat" do
    test "returns 200 with text/plain stat summary and cache headers", %{conn: conn} do
      conn = get(conn, ~p"/compare/1.7.1...1.7.14/diff/stat")

      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["text/plain"]
      assert get_resp_header(conn, "cache-control") == ["public, max-age=86400"]
      assert conn.resp_body =~ "files changed"
    end

    test "returns 200 with empty body for identical versions", %{conn: conn} do
      conn = get(conn, ~p"/compare/1.7.1...1.7.1/diff/stat")

      assert conn.status == 200
      assert conn.resp_body == ""
    end

    test "works with non-default app spec variant", %{conn: conn} do
      conn = get(conn, ~p"/compare/1.5.0 --live...1.5.1 --live/diff/stat")

      assert conn.status == 200
    end

    test "returns 404 for unknown version without public cache headers", %{conn: conn} do
      {_status, headers, _body} =
        assert_error_sent(404, fn -> get(conn, ~p"/compare/0.0.0...1.7.14/diff/stat") end)

      assert {"cache-control", "max-age=0, private, must-revalidate"} in headers
    end

    test "returns 404 for malformed diff spec", %{conn: conn} do
      assert_error_sent(404, fn -> get(conn, ~p"/compare/not-a-version/diff/stat") end)
    end
  end
end
