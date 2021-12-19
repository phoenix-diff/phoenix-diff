defmodule PhxDiff.TestSupport.Sigils do
  @moduledoc """
  Sigils to be used in test cases
  """

  @doc """
  Handles ~V for Versions
  """
  defmacro sigil_V(term, modifiers)

  defmacro sigil_V({:<<>>, _, [string]}, []) do
    version = Version.parse!(string)
    Macro.escape(version)
  end
end
