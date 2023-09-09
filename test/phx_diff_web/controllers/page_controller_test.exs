defmodule PhxDiffWeb.PageControllerTest do
  use PhxDiffWeb.ConnCase, async: true

  describe "GET /" do
    test "redirects to /compare", %{conn: conn} do
      assert conn
             |> get(~p"/")
             |> redirected_to() =~ ~p"/compare"
    end
  end
end
