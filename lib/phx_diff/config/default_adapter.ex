defmodule PhxDiff.Config.DefaultAdapter do
  @moduledoc false

  @behaviour PhxDiff.Config.Adapter

  @impl true
  def app_repo_path, do: Application.app_dir(:phx_diff, "priv/data/sample-app")

  @impl true
  def app_repo_store, do: Application.fetch_env!(:phx_diff, :app_repo_store)

  @impl true
  def app_repo_backend do
    case System.get_env("APP_REPO_BACKEND", "file_system") do
      "s3" -> :s3
      _ -> :file_system
    end
  end

  @impl true
  def app_repo_cache_path do
    System.get_env(
      "APP_REPO_CACHE_PATH",
      Path.join(System.tmp_dir!(), "phx-diff/sample-app-cache")
    )
  end

  @impl true
  def app_repo_s3_bucket do
    System.fetch_env!("APP_REPO_S3_BUCKET")
  end

  @impl true
  def app_repo_s3_prefix do
    System.get_env("APP_REPO_S3_PREFIX", "sample-app")
  end

  @impl true
  def app_repo_s3_region do
    System.get_env("AWS_REGION", "auto")
  end

  @impl true
  def github_sample_app_base_url,
    do: Application.fetch_env!(:phx_diff, :github_sample_app_base_url)

  @impl true
  def app_generator_workspace_path, do: "tmp"

  @impl true
  def s3_base_url do
    System.get_env("AWS_ENDPOINT_URL_S3") || Application.fetch_env!(:phx_diff, :s3_base_url)
  end
end
