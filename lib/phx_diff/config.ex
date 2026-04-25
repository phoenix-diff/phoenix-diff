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
  @spec app_repo_store() :: module()
  def app_repo_store do
    adapter().app_repo_store()
  end

  @impl true
  @spec app_repo_backend() :: :file_system | :s3
  def app_repo_backend do
    adapter().app_repo_backend()
  end

  @impl true
  @spec app_repo_cache_path() :: String.t()
  def app_repo_cache_path do
    adapter().app_repo_cache_path()
  end

  @impl true
  @spec app_repo_s3_bucket() :: String.t()
  def app_repo_s3_bucket do
    adapter().app_repo_s3_bucket()
  end

  @impl true
  @spec app_repo_s3_prefix() :: String.t()
  def app_repo_s3_prefix do
    adapter().app_repo_s3_prefix()
  end

  @impl true
  @spec app_repo_s3_region() :: String.t()
  def app_repo_s3_region do
    adapter().app_repo_s3_region()
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
  def s3_base_url do
    adapter().s3_base_url()
  end

  defp adapter do
    Application.get_env(:phx_diff, :config_adapter, PhxDiff.Config.DefaultAdapter)
  end
end
