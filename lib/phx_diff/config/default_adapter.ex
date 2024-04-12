defmodule PhxDiff.Config.DefaultAdapter do
  @moduledoc false

  @behaviour PhxDiff.Config.Adapter

  @impl true
  def app_repo_path, do: Application.app_dir(:phx_diff, "priv/data/sample-app")

  @impl true
  def github_sample_app_base_url,
    do: Application.fetch_env!(:phx_diff, :github_sample_app_base_url)

  @impl true
  def app_generator_workspace_path, do: "tmp"
end
