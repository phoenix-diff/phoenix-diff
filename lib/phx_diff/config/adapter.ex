defmodule PhxDiff.Config.Adapter do
  @moduledoc false

  @callback app_repo_path() :: String.t()
  @callback app_generator_workspace_path() :: String.t()
end
