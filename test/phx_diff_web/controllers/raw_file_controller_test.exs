defmodule PhxDiffWeb.RawFileControllerTest do
  use PhxDiffWeb.ConnCase, async: true

  import Mox

  alias PhxDiff.S3Simulator

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

    @tag :tmp_dir
    test "returns 503 when app storage is unavailable", %{conn: conn, tmp_dir: tmp_dir} do
      sim = start_supervised!(S3Simulator)
      S3Simulator.trigger_internal_server_errors(sim, operation: :get_object)

      stub_s3_repo_config(S3Simulator.base_url(sim), tmp_dir)

      assert_error_sent(503, fn -> get(conn, ~p"/browse/1.7.1/raw/mix.exs") end)
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
