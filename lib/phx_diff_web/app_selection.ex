defmodule PhxDiffWeb.AppSelection do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias PhxDiff.AppSpecification
  alias PhxDiffWeb.CompareLive.DiffSelection.Fields
  alias PhxDiffWeb.CompareLive.DiffSelection.PhxNewArgListPresets

  @type variant :: :default | :no_ecto | :live | :no_live | :no_html | :binary_id | :umbrella

  @type t :: %__MODULE__{
          version: Version.t() | nil,
          variant: variant | nil
        }

  @primary_key false
  embedded_schema do
    field :version, Fields.Version

    field :variant, Ecto.Enum,
      values: [:default, :no_ecto, :live, :no_live, :no_html, :binary_id, :umbrella]
  end

  def new(%AppSpecification{} = app_spec) do
    %__MODULE__{
      version: app_spec.phoenix_version,
      variant: PhxNewArgListPresets.preset_from_arg_list(app_spec.phx_new_arguments).id
    }
  end

  def changeset(data, params) do
    data
    |> cast(params, [:version, :variant])
    |> validate_required([:version, :variant])
    |> validate_variant()
  end

  def validate_variant(changeset) do
    with %Version{} = version <- get_field(changeset, :version),
         false <- get_field(changeset, :variant) in variant_ids_for_version(version) do
      add_error(changeset, :variant, "is unknown")
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
