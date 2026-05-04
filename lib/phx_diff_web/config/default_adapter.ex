defmodule PhxDiffWeb.Config.DefaultAdapter do
  @moduledoc false
  @behaviour PhxDiffWeb.Config.Adapter

  alias PhxDiffWeb.Config.AdminDashboardCredential

  @impl true
  def admin_dashboard_credentials do
    %AdminDashboardCredential{
      username: Application.fetch_env!(:phx_diff, :admin_username),
      password: Application.fetch_env!(:phx_diff, :admin_password)
    }
  end
end
