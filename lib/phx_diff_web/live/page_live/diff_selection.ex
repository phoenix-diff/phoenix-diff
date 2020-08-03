defmodule PhxDiffWeb.PageLive.DiffSelection do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  alias PhxDiff.Diffs

  embedded_schema do
    field :source, :string
    field :target, :string
  end

  def changeset(data, params \\ %{}) do
    data
    |> cast(params, [:source, :target])
    |> validate_required([:source, :target])
    |> validate_inclusion(:source, Diffs.all_versions())
    |> validate_inclusion(:target, Diffs.all_versions())
  end
end
