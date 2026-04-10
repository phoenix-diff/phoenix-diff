defmodule PhxDiffWeb.DiffManifestControllerTest do
  use PhxDiffWeb.ConnCase, async: true

  describe "GET /compare/:diff_specification/diff/manifest" do
    test "returns 200 with correct response headers", %{conn: conn} do
      conn = get(conn, ~p"/compare/1.7.14...1.8.0/diff/manifest")

      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]
      assert get_resp_header(conn, "cache-control") == ["public, max-age=86400"]
      assert get_resp_header(conn, "content-disposition") == []
    end

    test "source and target are structured version+flags objects for default app specs", %{
      conn: conn
    } do
      conn = get(conn, ~p"/compare/1.7.14...1.8.0/diff/manifest")
      body = Jason.decode!(conn.resp_body)

      assert body["source"] == %{"version" => "1.7.14", "flags" => []}
      assert body["target"] == %{"version" => "1.8.0", "flags" => []}
    end

    test "source and target include phx.new flags for flagged app specs", %{conn: conn} do
      conn = get(conn, ~p"/compare/1.7.14 --no-ecto...1.8.0 --no-ecto/diff/manifest")
      body = Jason.decode!(conn.resp_body)

      assert body["source"] == %{"version" => "1.7.14", "flags" => ["--no-ecto"]}
      assert body["target"] == %{"version" => "1.8.0", "flags" => ["--no-ecto"]}
    end

    test "totals are consistent with the files array", %{conn: conn} do
      conn = get(conn, ~p"/compare/1.7.14 --no-ecto...1.8.0 --no-ecto/diff/manifest")
      body = Jason.decode!(conn.resp_body)

      non_binary = Enum.reject(body["files"], & &1["binary"])

      assert body["total_files"] == length(body["files"])
      assert body["total_added"] == Enum.sum(Enum.map(non_binary, &Map.get(&1, "added", 0)))
      assert body["total_deleted"] == Enum.sum(Enum.map(non_binary, &Map.get(&1, "deleted", 0)))
    end

    test "files are ordered alphabetically by path", %{conn: conn} do
      conn = get(conn, ~p"/compare/1.7.14 --no-ecto...1.8.0 --no-ecto/diff/manifest")
      body = Jason.decode!(conn.resp_body)

      paths = Enum.map(body["files"], & &1["path"])
      assert paths == Enum.sort(paths)
    end

    test "added text file entry shape", %{conn: conn} do
      conn = get(conn, ~p"/compare/1.7.14 --no-ecto...1.8.0 --no-ecto/diff/manifest")
      body = Jason.decode!(conn.resp_body)

      entry = Enum.find(body["files"], &(&1["path"] == "AGENTS.md"))

      assert entry == %{
               "path" => "AGENTS.md",
               "status" => "added",
               "added" => 291,
               "deleted" => 0
             }
    end

    test "deleted text file entry shape", %{conn: conn} do
      conn = get(conn, ~p"/compare/1.7.14 --no-ecto...1.8.0 --no-ecto/diff/manifest")
      body = Jason.decode!(conn.resp_body)

      entry = Enum.find(body["files"], &(&1["path"] == "assets/tailwind.config.js"))

      assert entry == %{
               "path" => "assets/tailwind.config.js",
               "status" => "deleted",
               "added" => 0,
               "deleted" => 74
             }
    end

    test "modified text file entry shape", %{conn: conn} do
      conn = get(conn, ~p"/compare/1.7.14 --no-ecto...1.8.0 --no-ecto/diff/manifest")
      body = Jason.decode!(conn.resp_body)

      entry = Enum.find(body["files"], &(&1["path"] == "README.md"))

      assert entry == %{
               "path" => "README.md",
               "status" => "modified",
               "added" => 7,
               "deleted" => 7
             }
    end

    test "binary modified file entry shape", %{conn: conn} do
      conn = get(conn, ~p"/compare/1.7.0...1.7.14/diff/manifest")
      body = Jason.decode!(conn.resp_body)

      entry = Enum.find(body["files"], &(&1["path"] == "priv/static/favicon.ico"))

      assert entry == %{
               "path" => "priv/static/favicon.ico",
               "status" => "modified",
               "binary" => true
             }
    end

    test "all renamed entries have both path and old_path", %{conn: conn} do
      conn = get(conn, ~p"/compare/1.5.14...1.6.0/diff/manifest")
      body = Jason.decode!(conn.resp_body)

      renamed = Enum.filter(body["files"], &(&1["status"] == "renamed"))

      assert renamed != [], "expected at least one renamed entry"

      for file <- renamed do
        assert is_binary(file["path"])
        assert is_binary(file["old_path"])
      end
    end

    test "renamed text file with content changes entry shape", %{conn: conn} do
      conn = get(conn, ~p"/compare/1.5.14...1.6.0/diff/manifest")
      body = Jason.decode!(conn.resp_body)

      entry =
        Enum.find(
          body["files"],
          &(&1["path"] == "lib/sample_app_web/templates/layout/root.html.heex")
        )

      assert entry == %{
               "path" => "lib/sample_app_web/templates/layout/root.html.heex",
               "status" => "renamed",
               "old_path" => "lib/sample_app_web/templates/layout/app.html.eex",
               "added" => 7,
               "deleted" => 10
             }
    end

    test "pure renamed file entry shape", %{conn: conn} do
      conn = get(conn, ~p"/compare/1.5.14...1.6.0/diff/manifest")
      body = Jason.decode!(conn.resp_body)

      entry = Enum.find(body["files"], &(&1["path"] == "priv/static/robots.txt"))

      assert entry == %{
               "path" => "priv/static/robots.txt",
               "status" => "renamed",
               "old_path" => "assets/static/robots.txt"
             }
    end

    test "binary renamed file entry shape", %{conn: conn} do
      conn = get(conn, ~p"/compare/1.5.14...1.6.0/diff/manifest")
      body = Jason.decode!(conn.resp_body)

      entry = Enum.find(body["files"], &(&1["path"] == "priv/static/favicon.ico"))

      assert entry == %{
               "path" => "priv/static/favicon.ico",
               "status" => "renamed",
               "old_path" => "assets/static/favicon.ico",
               "binary" => true
             }
    end

    test "identical source and target returns empty manifest", %{conn: conn} do
      conn = get(conn, ~p"/compare/1.7.14...1.7.14/diff/manifest")
      body = Jason.decode!(conn.resp_body)

      assert conn.status == 200

      assert body == %{
               "source" => %{"version" => "1.7.14", "flags" => []},
               "target" => %{"version" => "1.7.14", "flags" => []},
               "total_files" => 0,
               "total_added" => 0,
               "total_deleted" => 0,
               "files" => []
             }
    end

    test "returns 404 for unknown or malformed versions without public cache headers", %{
      conn: conn
    } do
      {_status, headers, _body} =
        assert_error_sent(404, fn -> get(conn, ~p"/compare/0.0.0...1.8.0/diff/manifest") end)

      assert {"cache-control", "no-store"} in headers

      assert_error_sent(404, fn -> get(conn, ~p"/compare/1.7.14...0.0.0/diff/manifest") end)
      assert_error_sent(404, fn -> get(conn, ~p"/compare/not-a-version/diff/manifest") end)

      assert_error_sent(404, fn -> get(conn, ~p"/compare/not-a-version...1.8.0/diff/manifest") end)

      assert_error_sent(404, fn ->
        get(conn, ~p"/compare/1.7.14...not-a-version/diff/manifest")
      end)
    end
  end
end
