defmodule PhxDiff.Config do
  @moduledoc false
  @behaviour PhxDiff.Config.Adapter

  use Boundary

  @impl true
  @spec app_repo_path() :: String.t()
  def app_repo_path do
    adapter().app_repo_path()
  end

  @impl true
  @spec app_repo_store() :: module()
  def app_repo_store do
    adapter().app_repo_store()
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

  @doc """
  Base URL for the S3 simulator.
  """
  @impl true
  @spec s3_base_url() :: String.t()
  def s3_base_url do
    adapter().s3_base_url()
  end

  @impl true
  @spec s3_access_key_id() :: String.t()
  def s3_access_key_id do
    adapter().s3_access_key_id()
  end

  @impl true
  @spec s3_secret_access_key() :: String.t()
  def s3_secret_access_key do
    adapter().s3_secret_access_key()
  end

  defp adapter do
    Application.get_env(:phx_diff, :config_adapter, PhxDiff.Config.DefaultAdapter)
  end
end
