defmodule PhxDiffWeb.DiffSelections.DiffSelection.PhxNewArgListPresets.PhxNewArgListPreset do
  @moduledoc false

  @type id :: atom
  @type t :: %__MODULE__{
          id: id,
          arg_list: [String.t()]
        }

  defstruct [:id, :arg_list]
end
