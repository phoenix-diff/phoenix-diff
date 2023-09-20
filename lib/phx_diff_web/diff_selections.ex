defmodule PhxDiffWeb.DiffSelections do
  @moduledoc false

  alias Ecto.Changeset
  alias PhxDiff.AppSpecification
  alias PhxDiffWeb.DiffSelections.DiffSelection
  alias PhxDiffWeb.DiffSelections.DiffSelection.PhxNewArgListPresets
  alias PhxDiffWeb.DiffSpecification

  @spec build_diff_specification(DiffSelection.t()) :: DiffSpecification.t()
  def build_diff_specification(%DiffSelection{} = diff_selection) do
    source = build_app_spec(diff_selection.source.version, diff_selection.source.variant)
    target = build_app_spec(diff_selection.target.version, diff_selection.target.variant)

    DiffSpecification.new(source, target)
  end

  @spec build_app_spec(Version.t(), atom) :: AppSpecification.t()
  def build_app_spec(version, variant_id) do
    {:ok, preset} = PhxNewArgListPresets.fetch(variant_id)
    AppSpecification.new(version, preset.arg_list)
  end

  @spec find_valid_diff_selection(Changeset.t(DiffSelection.t())) :: DiffSelection.t()
  def find_valid_diff_selection(%Changeset{valid?: true} = changeset),
    do: Changeset.apply_action!(changeset, :validate)

  def find_valid_diff_selection(%Changeset{} = changeset) do
    errors = Changeset.traverse_errors(changeset, &Function.identity/1)
    diff = Changeset.apply_changes(changeset)

    changeset =
      case errors do
        %{source: [_ | _]} ->
          DiffSelection.changeset(
            changeset.data,
            Map.put(
              changeset.params,
              "source",
              default_params_for_version(PhxDiff.previous_release_version())
            )
          )

        %{target: [_ | _]} ->
          DiffSelection.changeset(
            changeset.data,
            Map.put(
              changeset.params,
              "target",
              default_params_for_version(PhxDiff.latest_version())
            )
          )

        %{source: %{version: _}} ->
          DiffSelection.changeset(
            changeset.data,
            put_in(
              changeset.params,
              ["source", "version"],
              PhxDiff.previous_release_version() |> to_string()
            )
          )

        %{target: %{version: _}} ->
          DiffSelection.changeset(
            changeset.data,
            put_in(
              changeset.params,
              ["target", "version"],
              PhxDiff.latest_version() |> to_string()
            )
          )

        %{source: %{variant: _}} ->
          default_variant = PhxNewArgListPresets.get_default_for_version(diff.source.version)

          if diff.source.variant == default_variant.id do
            DiffSelection.changeset(
              changeset.data,
              Map.put(
                changeset.params,
                "source",
                default_params_for_version(PhxDiff.previous_release_version())
              )
            )
          else
            DiffSelection.changeset(
              changeset.data,
              put_in(changeset.params, ["source", "variant"], to_string(default_variant.id))
            )
          end

        %{target: %{variant: _}} ->
          default_variant = PhxNewArgListPresets.get_default_for_version(diff.target.version)

          if diff.target.variant == default_variant.id do
            DiffSelection.changeset(
              changeset.data,
              Map.put(
                changeset.params,
                "target",
                default_params_for_version(PhxDiff.latest_version())
              )
            )
          else
            DiffSelection.changeset(
              changeset.data,
              put_in(changeset.params, ["target", "variant"], to_string(default_variant.id))
            )
          end
      end

    find_valid_diff_selection(changeset)
  end

  defp default_params_for_version(version) do
    default_variant = PhxNewArgListPresets.get_default_for_version(version)

    %{
      "version" => to_string(version),
      "variant" => to_string(default_variant.id)
    }
  end
end
