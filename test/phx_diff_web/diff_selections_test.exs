defmodule PhxDiffWeb.DiffSelectionsTest do
  use PhxDiff.MockedConfigCase, async: true

  import PhxDiff.TestSupport.Sigils

  alias PhxDiffWeb.DiffSelections
  alias PhxDiffWeb.CompareLive.DiffSelection

  @unknown_phoenix_version "0.0.99"

  describe "find_valid_diff_selection/1" do
    test "defaults to previous version and latest version when given no params" do
      changeset = DiffSelection.changeset(%DiffSelection{})

      assert DiffSelections.find_valid_diff_selection(changeset) ==
               %DiffSelection{
                 source: PhxDiff.previous_release_version(),
                 source_variant: :default,
                 target: PhxDiff.latest_version(),
                 target_variant: :default
               }
    end

    test "1.5.x defaults to --live variants" do
      changeset =
        DiffSelection.changeset(
          %DiffSelection{},
          %{"source" => "1.5.0", "target" => "1.5.1"}
        )

      assert DiffSelections.find_valid_diff_selection(changeset) ==
               %DiffSelection{
                 source: ~V|1.5.0|,
                 source_variant: :live,
                 target: ~V|1.5.1|,
                 target_variant: :live
               }
    end

    test "falls back to previous version when source is unknown" do
      changeset =
        DiffSelection.changeset(
          %DiffSelection{},
          %{"source" => @unknown_phoenix_version, "target" => "1.5.1"}
        )

      assert DiffSelections.find_valid_diff_selection(changeset) ==
               %DiffSelection{
                 source: PhxDiff.previous_release_version(),
                 source_variant: :default,
                 target: ~V|1.5.1|,
                 target_variant: :live
               }
    end

    test "falls back to latest version when target is unknown" do
      changeset =
        DiffSelection.changeset(
          %DiffSelection{},
          %{
            "source" => "1.4.0",
            "target" => @unknown_phoenix_version
          }
        )

      assert DiffSelections.find_valid_diff_selection(changeset) ==
               %DiffSelection{
                 source: ~V|1.4.0|,
                 source_variant: :default,
                 target: PhxDiff.latest_version(),
                 target_variant: :default
               }
    end

    test "falls back to the default variant when the source_variant is unknown" do
      changeset =
        DiffSelection.changeset(
          %DiffSelection{},
          %{
            "source" => "1.4.0",
            "source_variant" => "invalid",
            "target" => "1.6.0"
          }
        )

      assert DiffSelections.find_valid_diff_selection(changeset) ==
               %DiffSelection{
                 source: ~V|1.4.0|,
                 source_variant: :default,
                 target: ~V|1.6.0|,
                 target_variant: :default
               }
    end

    test "falls back to the default variant when the target_variant is unknown" do
      changeset =
        DiffSelection.changeset(
          %DiffSelection{},
          %{
            "source" => "1.4.0",
            "target" => "1.6.0",
            "target_variant" => "invalid"
          }
        )

      assert DiffSelections.find_valid_diff_selection(changeset) ==
               %DiffSelection{
                 source: ~V|1.4.0|,
                 source_variant: :default,
                 target: ~V|1.6.0|,
                 target_variant: :default
               }
    end
  end
end
