defmodule PhxDiffWeb.CompareLive.DiffSelection do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  alias PhxDiff.AppSpecification
  alias PhxDiffWeb.CompareLive.DiffSelection.Fields
  alias PhxDiffWeb.CompareLive.DiffSelection.PhxNewArgListPresets

  @type variant :: :default | :no_ecto | :live | :no_live | :no_html | :binary_id | :umbrella

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
      values: [:default, :no_ecto, :live, :no_live, :no_html, :binary_id, :umbrella]

    field :target, Fields.Version

    field :target_variant, Ecto.Enum,
      values: [:default, :no_ecto, :live, :no_live, :no_html, :binary_id, :umbrella]
  end

  def new(%AppSpecification{} = source, %AppSpecification{} = target) do
    %__MODULE__{
      source: source.phoenix_version,
      source_variant: PhxNewArgListPresets.preset_from_arg_list(source.phx_new_arguments).id,
      target: target.phoenix_version,
      target_variant: PhxNewArgListPresets.preset_from_arg_list(target.phx_new_arguments).id
    }
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
