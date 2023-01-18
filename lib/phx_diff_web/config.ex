defmodule PhxDiffWeb.Config do
  @moduledoc false

  @behaviour PhxDiffWeb.Config.Adapter

  alias PhxDiffWeb.Config.AdminDashboardCredential

  @impl true
  @spec admin_dashboard_credentials() :: AdminDashboardCredential.t()
  def admin_dashboard_credentials do
    adapter().admin_dashboard_credentials()
  end

  defp adapter do
    Application.get_env(:phx_diff, :web_config_adapter, PhxDiffWeb.Config.DefaultAdapter)
  end
end
