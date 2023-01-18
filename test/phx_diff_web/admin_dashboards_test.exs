defmodule PhxDiffWeb.AdminDashboardsTest do
  use PhxDiffWeb.ConnCase, async: true
  use PhxDiff.MockedConfigCase

  import Plug.BasicAuth, only: [encode_basic_auth: 2]
  import Mox

  alias PhxDiffWeb.Config.AdminDashboardCredential

  describe "Live Dashboard" do
    setup do
      stub(PhxDiffWeb.Config.Mock, :admin_dashboard_credentials, fn ->
        %AdminDashboardCredential{username: "user", password: "valid"}
      end)

      :ok
    end

    test "is accessible when signed in as admin", %{conn: conn} do
      conn
      |> put_req_header("authorization", encode_basic_auth("user", "valid"))
      |> get(~p"/dashboard/home")
      |> html_response(:ok)
    end

    test "is blocked with invalid credentials", %{conn: conn} do
      conn
      |> put_req_header("authorization", encode_basic_auth("user", "invalid"))
      |> get(~p"/dashboard/home")
      |> response(:unauthorized)
    end

    test "is not accessible when unauthenticated", %{conn: conn} do
      get(conn, ~p"/dashboard/home")
      |> response(:unauthorized)
    end
  end
end
