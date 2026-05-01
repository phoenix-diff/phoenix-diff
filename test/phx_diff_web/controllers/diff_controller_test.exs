defmodule PhxDiffWeb.DiffControllerTest do
  use PhxDiffWeb.ConnCase, async: true

  import Mox

  alias PhxDiff.S3Simulator

  describe "GET /compare/:diff_specification/diff" do
    test "returns 200 with correct response headers", %{conn: conn} do
      conn = get(conn, ~p"/compare/1.7.14...1.8.0/diff")

      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["text/plain; charset=utf-8"]
      assert get_resp_header(conn, "cache-control") == ["public, max-age=86400"]

      assert get_resp_header(conn, "content-disposition") == [
               "inline; filename=\"1.7.14...1.8.0.diff\""
             ]
    end

    test "accepts text/plain requests", %{conn: conn} do
      conn =
        conn
        |> put_req_header("accept", "text/plain")
        |> get(~p"/compare/1.7.14...1.8.0/diff")

      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["text/plain; charset=utf-8"]
    end

    test "content-disposition filename includes flags for non-default app specs", %{conn: conn} do
      conn = get(conn, ~p"/compare/1.7.14 --no-ecto...1.8.0 --no-ecto/diff")

      assert get_resp_header(conn, "content-disposition") == [
               "inline; filename=\"1.7.14 --no-ecto...1.8.0 --no-ecto.diff\""
             ]
    end

    test "response body is a unified diff containing changed files", %{conn: conn} do
      conn = get(conn, ~p"/compare/1.7.14...1.8.0/diff")

      assert String.starts_with?(conn.resp_body, "diff --git ")
      assert conn.resp_body =~ "--- a/"
      assert conn.resp_body =~ "+++ b/"
      assert conn.resp_body =~ "mix.exs"
    end

    test "identical source and target returns 200 with empty body", %{conn: conn} do
      conn = get(conn, ~p"/compare/1.7.14...1.7.14/diff")

      assert conn.status == 200
      assert conn.resp_body == ""
    end

    test "?include= filters diff to matching path prefix", %{conn: conn} do
      conn = get(conn, ~p"/compare/1.7.14...1.8.0/diff?include=mix.exs")

      assert conn.status == 200
      assert conn.resp_body =~ "mix.exs"
      refute conn.resp_body =~ "README.md"
    end

    test "multiple ?include= params are combined as a union", %{conn: conn} do
      conn = get(conn, ~p"/compare/1.7.14...1.8.0/diff?include=mix.exs&include=README.md")

      assert conn.status == 200
      assert conn.resp_body =~ "mix.exs"
      assert conn.resp_body =~ "README.md"
    end

    test "?include= prefix matches all files under that path", %{conn: conn} do
      conn = get(conn, ~p"/compare/1.7.14...1.8.0/diff?include=config")

      assert conn.status == 200
      assert conn.resp_body =~ "config/"
      refute conn.resp_body =~ "mix.exs"
    end

    test "?include= matches renamed files by their source path too", %{conn: conn} do
      conn =
        get(
          conn,
          ~p"/compare/1.5.14...1.6.0/diff?include=lib/sample_app_web/templates/layout/app.html.eex"
        )

      assert conn.status == 200
      assert conn.resp_body =~ "rename from lib/sample_app_web/templates/layout/app.html.eex"
      assert conn.resp_body =~ "rename to lib/sample_app_web/templates/layout/root.html.heex"
    end

    test "?include= matching no files in a valid comparison returns 200 with empty body", %{
      conn: conn
    } do
      conn = get(conn, ~p"/compare/1.7.14...1.8.0/diff?include=nonexistent_path")

      assert conn.status == 200
      assert conn.resp_body == ""
    end

    test "returns 404 for unknown or malformed versions without public cache headers", %{
      conn: conn
    } do
      {_status, headers, _body} =
        assert_error_sent(404, fn -> get(conn, ~p"/compare/0.0.0...1.8.0/diff") end)

      assert {"cache-control", "no-store"} in headers

      assert_error_sent(404, fn -> get(conn, ~p"/compare/1.7.14...0.0.0/diff") end)
      assert_error_sent(404, fn -> get(conn, ~p"/compare/not-a-version/diff") end)
      assert_error_sent(404, fn -> get(conn, ~p"/compare/not-a-version...1.8.0/diff") end)

      assert_error_sent(404, fn ->
        get(conn, ~p"/compare/1.7.14...not-a-version/diff")
      end)
    end

    @tag :tmp_dir
    test "returns 503 when app storage is unavailable", %{conn: conn, tmp_dir: tmp_dir} do
      sim = start_supervised!(S3Simulator)
      S3Simulator.trigger_internal_server_errors(sim, operation: :get_object)

      stub_s3_repo_config(S3Simulator.base_url(sim), tmp_dir)

      {_status, headers, _body} =
        assert_error_sent(503, fn -> get(conn, ~p"/compare/1.7.14...1.8.0/diff") end)

      assert {"cache-control", "no-store"} in headers
    end
  end

  defp stub_s3_repo_config(endpoint, tmp_dir) do
    PhxDiff.Config.Mock
    |> stub(:app_repo_store, fn -> PhxDiff.Diffs.AppRepo.Store.S3 end)
    |> stub(:app_repo_cache_path, fn -> Path.join(tmp_dir, "cache") end)
    |> stub(:app_repo_s3_bucket, fn -> "sample-apps" end)
    |> stub(:app_repo_s3_prefix, fn -> "sample-app" end)
    |> stub(:app_repo_s3_region, fn -> "us-east-1" end)
    |> stub(:s3_base_url, fn -> endpoint end)
  end
end
