defmodule PhxDiffWeb.CompareLive.DiffSelection do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  alias PhxDiff.AppSpecification
  alias PhxDiffWeb.AppSelection

  @type t :: %__MODULE__{
          source: AppSelection.t() | nil,
          target: AppSelection.t() | nil
        }

  @primary_key false
  embedded_schema do
    embeds_one :source, AppSelection, on_replace: :update
    embeds_one :target, AppSelection, on_replace: :update
  end

  def new(%AppSpecification{} = source, %AppSpecification{} = target) do
    %__MODULE__{
      source: AppSelection.new(source),
      target: AppSelection.new(target)
    }
  end

  def changeset(data, params \\ %{}) do
    data
    |> cast(params, [])
    |> cast_embed(:source)
    |> cast_embed(:target)
    |> validate_required([:source, :target])
  end
end
