defmodule PhxDiffWeb.Config.Adapter do
  @moduledoc false

  alias PhxDiffWeb.Config.AdminDashboardCredential

  @callback admin_dashboard_credentials() :: AdminDashboardCredential.t()
end
