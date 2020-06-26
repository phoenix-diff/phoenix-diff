defmodule PhxDiff.Diffs.AppSpecification do
  @moduledoc """
  A specification for the application that should be compared
  """

  defstruct [:phoenix_version]

  @type version :: PhxDiff.Diffs.version()
  @type t :: %__MODULE__{
          phoenix_version: version
        }

  @doc """
  Builds an new app specification for a basic phoenix app with no options
  """
  @spec new(version) :: t
  def new(phoenix_version) when is_binary(phoenix_version) do
    %__MODULE__{phoenix_version: phoenix_version}
  end
end
