defmodule PhoenixDiff.DiffsControllerTest do
  use PhoenixDiff.ConnCase

  describe "GET show" do
    test "returns 404 if versions are not given", %{conn: conn} do
      conn = conn |> get("/diffs")

      assert response(conn, 404)
    end

    test "returns empty response if versions are not valid", %{conn: conn} do
      conn = conn |> get("/diffs/xxx/yyy")

      assert text_response(conn, 200) == ""
    end

    test "returns empty response if versions are the same", %{conn: conn} do
      conn = conn |> get("/diffs/1.2.0/1.2.0")

      assert text_response(conn, 200) == ""
    end

    test "returns diff if versions are the valid", %{conn: conn} do
      conn = conn |> get("/diffs/1.2.0/1.2.1")

      assert text_response(conn, 200) =~ "diff --git config/prod.exs config/prod.exs"
    end
  end
end
