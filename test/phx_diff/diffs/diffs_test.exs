defmodule PhxDiff.DiffsTest do
  use ExUnit.Case, async: true

  import PhxDiff.TestSupport.FileHelpers

  alias PhxDiff.Diffs

  alias PhxDiff.Diffs.{
    AppSpecification,
    Config
  }

  describe "all_versions/1" do
    test "returns all versions" do
      versions = Diffs.all_versions()

      assert versions |> length() > 25

      assert versions |> Enum.member?("1.3.0")
      assert versions |> Enum.member?("1.4.0-rc.2")
    end

    test "returns an empty list when no apps have been generated" do
      with_tmp(fn path ->
        config = build_config(path)

        assert [] = Diffs.all_versions(config: config)
      end)
    end
  end

  describe "release_versions/1" do
    test "returns all versions" do
      versions = Diffs.release_versions()

      assert versions |> length() > 20

      assert versions |> Enum.member?("1.3.0")
      refute versions |> Enum.member?("1.4.0-rc.2")
    end

    test "returns an empty list when no apps have been generated" do
      with_tmp(fn path ->
        config = build_config(path)

        assert [] = Diffs.release_versions(config: config)
      end)
    end
  end

  describe "get_diff/3" do
    test "returns content when versions are valid" do
      source = AppSpecification.new("1.3.1")
      target = AppSpecification.new("1.3.2")

      {:ok, diff} = Diffs.get_diff(source, target)

      assert diff =~ "config/config.exs config/config.exs"
    end

    test "returns empty when versions are the same" do
      source = AppSpecification.new("1.3.1")
      target = AppSpecification.new("1.3.1")

      {:ok, diff} = Diffs.get_diff(source, target)

      assert diff == ""
    end

    test "returns error when a version is invalid" do
      source = AppSpecification.new("1.3.1")
      target = AppSpecification.new("invalid")

      {:error, :invalid_versions} = Diffs.get_diff(source, target)
    end

    test "returns an error when an app hasn't been generated for the given version" do
      with_tmp(fn path ->
        config = build_config(path)

        source = AppSpecification.new("1.3.1")
        target = AppSpecification.new("1.4.2")

        assert {:error, :invalid_versions} = Diffs.get_diff(source, target, config: config)
      end)
    end
  end

  defp build_config(tmp_path) do
    %Config{app_repo_path: tmp_path}
  end
end
