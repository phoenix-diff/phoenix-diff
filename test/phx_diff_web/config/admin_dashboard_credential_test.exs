defmodule PhxDiffWeb.Config.AdminDashboardCredentialTest do
  use ExUnit.Case, async: true

  alias PhxDiffWeb.Config.AdminDashboardCredential

  test "hides the password field when inspecting" do
    credential = %AdminDashboardCredential{username: "myusername", password: "mypassword"}

    output = inspect(credential)

    assert output =~ "myusername"
    refute output =~ "mypassword"
  end
end
