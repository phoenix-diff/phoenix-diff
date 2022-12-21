defmodule PhxDiffWeb.PageLive.DiffSelection do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  alias PhxDiffWeb.PageLive.DiffSelection.Fields
  alias PhxDiffWeb.PageLive.DiffSelection.PhxNewArgListPresets

  @type variant :: :default | :no_ecto | :live

  @type t :: %__MODULE__{
          source: Version.t() | nil,
          source_variant: variant | nil,
          target: Version.t() | nil,
          target_variant: variant | nil
        }

  @primary_key false
  embedded_schema do
    field :source, Fields.Version

    field :source_variant, Ecto.Enum,
      values: [default: "default", live: "live", no_ecto: "no-ecto"]

    field :target, Fields.Version

    field :target_variant, Ecto.Enum,
      values: [default: "default", live: "live", no_ecto: "no-ecto"]
  end

  def changeset(data, params \\ %{}) do
    all_versions = PhxDiff.all_versions()

    data
    |> cast(params, [:source, :source_variant, :target, :target_variant])
    |> validate_required([:source, :target, :source_variant, :target_variant])
    |> validate_inclusion(:source, all_versions)
    |> validate_inclusion(:target, all_versions)
    |> validate_variant(:source_variant, :source)
    |> validate_variant(:target_variant, :target)
  end

  defp validate_variant(changeset, field, version_field) do
    with %Version{} = version <- get_field(changeset, version_field),
         false <- get_field(changeset, field) in variant_ids_for_version(version) do
      add_error(changeset, field, "is unknown")
    else
      _ -> changeset
    end
  end

  defp variant_ids_for_version(version) do
    version
    |> PhxNewArgListPresets.list_known_presets_for_version()
    |> Enum.map(& &1.id)
  end
end
