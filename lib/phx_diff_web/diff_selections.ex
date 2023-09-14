defmodule PhxDiffWeb.DiffSelections do
  @moduledoc false

  alias Ecto.Changeset
  alias PhxDiffWeb.CompareLive.DiffSelection
  alias PhxDiffWeb.CompareLive.DiffSelection.PhxNewArgListPresets

  @spec find_valid_diff_selection(Changeset.t(DiffSelection.t())) :: DiffSelection.t()
  def find_valid_diff_selection(changeset) do
    diff_selection = Changeset.apply_changes(changeset)
    error_fields = Keyword.keys(changeset.errors)

    diff_selection =
      if :source in error_fields do
        %{diff_selection | source: PhxDiff.previous_release_version()}
      else
        diff_selection
      end

    diff_selection =
      if :target in error_fields do
        %{diff_selection | target: PhxDiff.latest_version()}
      else
        diff_selection
      end

    diff_selection =
      if :source_variant in error_fields do
        %{
          diff_selection
          | source_variant: PhxNewArgListPresets.get_default_for_version(diff_selection.source).id
        }
      else
        diff_selection
      end

    diff_selection =
      if :target_variant in error_fields do
        %{
          diff_selection
          | target_variant: PhxNewArgListPresets.get_default_for_version(diff_selection.target).id
        }
      else
        diff_selection
      end

    diff_selection
  end
end
