defmodule PhxDiffWeb.FileListControllerTest do
  use PhxDiffWeb.ConnCase, async: true

  import Mox

  alias PhxDiff.S3Simulator

  describe "GET /browse/:app_specification/files.txt" do
    test "returns 200 with text/plain file list and cache headers", %{conn: conn} do
      conn = get(conn, ~p"/browse/1.7.1/files.txt")

      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["text/plain"]
      assert get_resp_header(conn, "cache-control") == ["public, max-age=86400"]
      assert conn.resp_body =~ "mix.exs\n"
      assert conn.resp_body =~ ".gitignore\n"
      assert conn.resp_body =~ ".formatter.exs\n"
      assert String.ends_with?(conn.resp_body, "\n")
    end

    test "works with non-default app spec variant", %{conn: conn} do
      conn = get(conn, ~p"/browse/1.5.0 --live/files.txt")

      assert conn.status == 200
      assert conn.resp_body =~ "mix.exs\n"
    end

    test "returns 404 for unknown or malformed app spec without public cache headers", %{
      conn: conn
    } do
      {_status, headers, _body} =
        assert_error_sent(404, fn -> get(conn, ~p"/browse/0.0.0/files.txt") end)

      assert {"cache-control", "max-age=0, private, must-revalidate"} in headers

      assert_error_sent(404, fn -> get(conn, ~p"/browse/not-a-version/files.txt") end)
    end

    @tag :tmp_dir
    test "returns 503 when app storage is unavailable", %{conn: conn, tmp_dir: tmp_dir} do
      sim = start_supervised!(S3Simulator)
      S3Simulator.trigger_internal_server_errors(sim, operation: :get_object)

      stub_s3_repo_config(S3Simulator.base_url(sim), tmp_dir)

      assert_error_sent(503, fn -> get(conn, ~p"/browse/1.7.1/files.txt") end)
    end
  end

  defp stub_s3_repo_config(endpoint, tmp_dir) do
    PhxDiff.Config.Mock
    |> stub(:app_repo_backend, fn -> :s3 end)
    |> stub(:app_repo_cache_path, fn -> Path.join(tmp_dir, "cache") end)
    |> stub(:app_repo_s3_bucket, fn -> "sample-apps" end)
    |> stub(:app_repo_s3_prefix, fn -> "sample-app" end)
    |> stub(:app_repo_s3_region, fn -> "us-east-1" end)
    |> stub(:s3_base_url, fn -> endpoint end)
  end
end
