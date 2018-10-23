defmodule PhxDiff.DiffsTest do
  use ExUnit.Case, async: true

  alias PhxDiff.Diffs

  describe "all_versions/0" do
    test "returns all versions" do
      versions = Diffs.all_versions()

      assert versions |> length() > 25

      assert versions |> Enum.member?("1.3.0")
      assert versions |> Enum.member?("1.4.0-rc.2")
    end
  end

  describe "release_versions/0" do
    test "returns all versions" do
      versions = Diffs.release_versions()

      assert versions |> length() > 20

      assert versions |> Enum.member?("1.3.0")
      refute versions |> Enum.member?("1.4.0-rc.2")
    end
  end
end
