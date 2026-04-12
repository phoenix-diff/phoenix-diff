defmodule PhxDiff.Diff.Line do
  @moduledoc """
  A single line within a diff chunk.
  """

  defstruct [:type, :text, :raw]

  @type t :: %__MODULE__{
          type: :context | :add | :remove | :no_newline,
          text: String.t(),
          raw: String.t()
        }
end
