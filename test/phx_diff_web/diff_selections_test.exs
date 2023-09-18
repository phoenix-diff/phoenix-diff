defmodule PhxDiffWeb.DiffSelectionsTest do
  use PhxDiff.MockedConfigCase, async: true

  import PhxDiff.TestSupport.Sigils

  alias PhxDiffWeb.AppSelection
  alias PhxDiffWeb.CompareLive.DiffSelection
  alias PhxDiffWeb.DiffSelections

  @unknown_phoenix_version "0.0.99"

  describe "find_valid_diff_selection/1" do
    test "defaults to previous version and latest version when given no params" do
      changeset = DiffSelection.changeset(%DiffSelection{})

      assert DiffSelections.find_valid_diff_selection(changeset) ==
               %DiffSelection{
                 source: %AppSelection{
                   version: PhxDiff.previous_release_version(),
                   variant: :default
                 },
                 target: %AppSelection{
                   version: PhxDiff.latest_version(),
                   variant: :default
                 }
               }
    end

    test "1.5.x defaults to --live variants" do
      changeset =
        DiffSelection.changeset(
          %DiffSelection{},
          %{"source" => %{"version" => "1.5.0"}, "target" => %{"version" => "1.5.1"}}
        )

      assert DiffSelections.find_valid_diff_selection(changeset) ==
               %DiffSelection{
                 source: %AppSelection{
                   version: ~V|1.5.0|,
                   variant: :live
                 },
                 target: %AppSelection{
                   version: ~V|1.5.1|,
                   variant: :live
                 }
               }
    end

    test "falls back to previous version when source is unknown" do
      changeset =
        DiffSelection.changeset(
          %DiffSelection{},
          %{
            "source" => %{"version" => @unknown_phoenix_version},
            "target" => %{"version" => "1.5.1"}
          }
        )

      assert DiffSelections.find_valid_diff_selection(changeset) ==
               %DiffSelection{
                 source: %AppSelection{
                   version: PhxDiff.previous_release_version(),
                   variant: :default
                 },
                 target: %AppSelection{
                   version: ~V|1.5.1|,
                   variant: :live
                 }
               }
    end

    test "falls back to latest version when target is unknown" do
      changeset =
        DiffSelection.changeset(
          %DiffSelection{},
          %{
            "source" => %{"version" => "1.4.0"},
            "target" => %{"version" => @unknown_phoenix_version}
          }
        )

      assert DiffSelections.find_valid_diff_selection(changeset) ==
               %DiffSelection{
                 source: %AppSelection{
                   version: ~V|1.4.0|,
                   variant: :default
                 },
                 target: %AppSelection{
                   version: PhxDiff.latest_version(),
                   variant: :default
                 }
               }
    end

    test "falls back to the default variant when the source_variant is unknown" do
      changeset =
        DiffSelection.changeset(
          %DiffSelection{},
          %{
            "source" => %{"version" => "1.4.0", "variant" => "invalid"},
            "target" => %{"version" => "1.6.0"}
          }
        )

      assert DiffSelections.find_valid_diff_selection(changeset) ==
               %DiffSelection{
                 source: %AppSelection{
                   version: ~V|1.4.0|,
                   variant: :default
                 },
                 target: %AppSelection{
                   version: ~V|1.6.0|,
                   variant: :default
                 }
               }
    end

    test "falls back to the default variant when the target_variant is unknown" do
      changeset =
        DiffSelection.changeset(
          %DiffSelection{},
          %{
            "source" => %{"version" => "1.4.0"},
            "target" => %{"version" => "1.6.0", "variant" => "invalid"}
          }
        )

      assert DiffSelections.find_valid_diff_selection(changeset) ==
               %DiffSelection{
                 source: %AppSelection{
                   version: ~V|1.4.0|,
                   variant: :default
                 },
                 target: %AppSelection{
                   version: ~V|1.6.0|,
                   variant: :default
                 }
               }
    end
  end
end
