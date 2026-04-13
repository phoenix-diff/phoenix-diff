defmodule PhxDiffWeb.LLMTextControllerTest do
  use PhxDiffWeb.ConnCase, async: true

  describe "GET /llms.txt" do
    test "returns 200 with text/plain content type and expected content", %{conn: conn} do
      conn = get(conn, ~p"/llms.txt")

      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["text/plain; charset=utf-8"]
      assert conn.resp_body =~ "PhxDiff"
      assert conn.resp_body =~ "/versions"
    end
  end
end
