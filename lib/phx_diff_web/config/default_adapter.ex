defmodule PhxDiffWeb.Config.DefaultAdapter do
  @moduledoc false
  alias PhxDiffWeb.Config.AdminDashboardCredential

  @behaviour PhxDiffWeb.Config.Adapter

  @impl true
  def admin_dashboard_credentials do
    %AdminDashboardCredential{
      username: Application.fetch_env!(:phx_diff, :admin_username),
      password: Application.fetch_env!(:phx_diff, :admin_password)
    }
  end
end
