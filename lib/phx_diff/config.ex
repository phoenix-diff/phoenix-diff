defmodule PhxDiff.Config do
  @moduledoc false
  use Boundary

  @behaviour PhxDiff.Config.Adapter

  @impl true
  @spec app_repo_path() :: String.t()
  def app_repo_path do
    adapter().app_repo_path()
  end

  @impl true
  @spec app_generator_workspace_path() :: String.t()
  def app_generator_workspace_path do
    adapter().app_generator_workspace_path()
  end

  @impl true
  @spec github_sample_app_base_url() :: String.t()
  def github_sample_app_base_url do
    adapter().github_sample_app_base_url()
  end

  defp adapter do
    Application.get_env(:phx_diff, :config_adapter, PhxDiff.Config.DefaultAdapter)
  end
end
