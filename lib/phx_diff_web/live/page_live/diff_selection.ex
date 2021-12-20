defmodule PhxDiffWeb.PageLive.DiffSelection do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  alias PhxDiffWeb.PageLive.DiffSelection.Fields

  @type t :: %__MODULE__{
          source: Version.t() | nil,
          target: Version.t() | nil
        }

  @primary_key false
  embedded_schema do
    field :source, Fields.Version
    field :target, Fields.Version
  end

  def changeset(data, params \\ %{}) do
    data
    |> cast(params, [:source, :target])
    |> validate_required([:source, :target])
  end
end
