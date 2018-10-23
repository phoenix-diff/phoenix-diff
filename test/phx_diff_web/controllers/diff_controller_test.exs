defmodule PhxDiffWeb.DiffControllerTest do
  use PhxDiffWeb.ConnCase, async: true

  describe "GET index" do
    test "returns diff when versions are valid", %{conn: conn} do
      conn = conn |> get("/diffs?source=1.3.0&target=1.3.1")

      assert text_response(conn, 200) =~ "diff --git config/config.exs config/config.exs"
    end

    test "returns empty when versions are the same", %{conn: conn} do
      conn = conn |> get("/diffs?source=1.3.0&target=1.3.0")

      assert text_response(conn, 200) == ""
    end

    test "returns error when a version is invalid", %{conn: conn} do
      conn = conn |> get("/diffs?source=1.3.0&target=invalid")

      assert text_response(conn, 422) == "Invalid versions"
    end
  end
end
