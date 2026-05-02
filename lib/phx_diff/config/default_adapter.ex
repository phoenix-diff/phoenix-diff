defmodule PhxDiff.Config.DefaultAdapter do
  @moduledoc false

  @behaviour PhxDiff.Config.Adapter

  @impl true
  def app_repo_path, do: Application.app_dir(:phx_diff, "priv/data/sample-app")

  @impl true
  def app_repo_store, do: Application.fetch_env!(:phx_diff, :app_repo_store)

  @impl true
  def app_repo_cache_path, do: Application.fetch_env!(:phx_diff, :app_repo_cache_path)

  @impl true
  def app_repo_s3_bucket, do: Application.fetch_env!(:phx_diff, :app_repo_s3_bucket)

  @impl true
  def app_repo_s3_prefix, do: Application.fetch_env!(:phx_diff, :app_repo_s3_prefix)

  @impl true
  def app_repo_s3_region, do: Application.fetch_env!(:phx_diff, :app_repo_s3_region)

  @impl true
  def github_sample_app_base_url,
    do: Application.fetch_env!(:phx_diff, :github_sample_app_base_url)

  @impl true
  def app_generator_workspace_path, do: "tmp"

  @impl true
  def s3_base_url, do: Application.fetch_env!(:phx_diff, :s3_base_url)
end
