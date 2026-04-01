defmodule PhxDiffWeb.VersionControllerTest do
  use PhxDiffWeb.ConnCase, async: true

  describe "GET /versions" do
    test "returns 200 with text/plain content type and expected content", %{conn: conn} do
      conn = get(conn, ~p"/versions")

      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["text/plain"]
      assert conn.resp_body =~ "1.7.1"
      assert conn.resp_body =~ ~r/\d+\.\d+\.\d+: \w/
    end

    test "versions appear in descending order", %{conn: conn} do
      conn = get(conn, ~p"/versions")

      version_strings =
        conn.resp_body
        |> String.split("\n")
        |> Enum.reject(&(String.starts_with?(&1, "#") or &1 == ""))
        |> Enum.map(fn line ->
          [version | _] = String.split(line, ":")
          Version.parse!(String.trim(version))
        end)

      assert version_strings == Enum.sort(version_strings, {:desc, Version})
    end
  end
end
