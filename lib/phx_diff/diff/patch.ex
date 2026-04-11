defmodule PhxDiff.Diff.Patch do
  @moduledoc """
  A single file's changes within a git diff.
  """

  alias PhxDiff.Diff.Chunk

  defstruct [:from, :to, :trailing_newline, headers: %{}, chunks: [], raw_headers: []]

  @type t :: %__MODULE__{
          from: String.t() | nil,
          to: String.t() | nil,
          trailing_newline: boolean() | nil,
          headers: %{String.t() => String.t() | boolean()},
          chunks: [Chunk.t()],
          raw_headers: [String.t()]
        }
end
