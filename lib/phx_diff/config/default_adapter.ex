defmodule PhxDiff.Config.DefaultAdapter do
  @moduledoc false
  use Boundary

  @behaviour PhxDiff.Config.Adapter

  @impl true
  def app_repo_path, do: Application.app_dir(:phx_diff, "priv/data/sample-app")

  @impl true
  def app_generator_workspace_path, do: "tmp"
end
