defmodule PhxDiffWeb.DiffSelections.DiffSelection.PhxNewArgListPresets.PhxNewArgListPreset do
  @moduledoc false

  @type id :: atom
  @type t :: %__MODULE__{
          id: id,
          path: String.t(),
          arg_list: [String.t()]
        }

  defstruct [:id, :path, :arg_list]

  def path(id) do
    id
    |> to_string()
    |> String.replace("_", "-")
  end
end
