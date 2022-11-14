defmodule PhxDiff.Diffs.Config do
  @moduledoc false

  defstruct [:app_repo_path, :app_generator_workspace_path]

  @type t :: %__MODULE__{
          app_repo_path: String.t(),
          app_generator_workspace_path: String.t()
        }
end
