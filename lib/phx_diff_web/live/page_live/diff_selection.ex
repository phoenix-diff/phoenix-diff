defmodule PhxDiffWeb.PageLive.DiffSelection do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  alias PhxDiffWeb.PageLive.DiffSelection.Fields

  @type t :: %__MODULE__{
          source: Version.t() | nil,
          source_variant: [String.t()] | nil,
          target: Version.t() | nil,
          target_variant: [String.t()] | nil
        }

  @primary_key false
  embedded_schema do
    field :source, Fields.Version
    field :source_variant, Fields.Variant
    field :target, Fields.Version
    field :target_variant, Fields.Variant
  end

  def changeset(data, params \\ %{}) do
    data
    |> cast(params, [:source, :source_variant, :target, :target_variant])
    |> validate_required([:source, :target])
  end
end
