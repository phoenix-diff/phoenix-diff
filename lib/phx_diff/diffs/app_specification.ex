defmodule PhxDiff.Diffs.AppSpecification do
  @moduledoc """
  A specification for the application that should be compared
  """

  defstruct [:phoenix_version, :phx_new_arguments]

  @type version :: PhxDiff.Diffs.version()
  @type t :: %__MODULE__{
          phoenix_version: version,
          phx_new_arguments: [String.t()]
        }

  @doc false
  @spec new(Version.t(), [String.t()]) :: t
  def new(%Version{} = phoenix_version, phx_new_arguments) when is_list(phx_new_arguments) do
    %__MODULE__{phoenix_version: phoenix_version, phx_new_arguments: phx_new_arguments}
  end
end
