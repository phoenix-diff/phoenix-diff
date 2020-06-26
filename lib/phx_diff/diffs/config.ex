defmodule PhxDiff.Diffs.Config do
  @moduledoc """
  Configuration for PhxDiff
  """

  defstruct [:app_repo_path]

  @type t :: %__MODULE__{
          app_repo_path: String.t()
        }
end
