defmodule PhxDiff.Diff.Chunk do
  @moduledoc """
  A section of a patch grouped under a unified diff header delimited by @@ markers.
  """

  alias PhxDiff.Diff.Line

  defstruct [:header, :from_start, :from_count, :to_start, :to_count, :context, lines: []]

  @type t :: %__MODULE__{
          header: String.t(),
          from_start: non_neg_integer(),
          from_count: non_neg_integer(),
          to_start: non_neg_integer(),
          to_count: non_neg_integer(),
          context: String.t() | nil,
          lines: [Line.t()]
        }
end
