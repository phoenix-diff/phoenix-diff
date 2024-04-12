defmodule PhxDiff.Config.Adapter do
  @moduledoc false

  @callback app_repo_path() :: String.t()
  @callback app_generator_workspace_path() :: String.t()
  @callback github_sample_app_base_url() :: String.t()
end
