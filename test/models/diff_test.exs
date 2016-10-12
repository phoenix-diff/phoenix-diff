defmodule PhoenixDiff.DiffTest do
  use ExUnit.Case

  alias PhoenixDiff.Diff

  test "available_versions/0" do
    available_versions = Diff.available_versions

    assert available_versions |> is_list
    assert available_versions |> Enum.member?("1.2.0")
    assert available_versions |> Enum.member?("1.2.1")
  end

  test "get/2 returns empty string given same versions" do
    assert Diff.get("1.2.0", "1.2.0") == ""
  end

  test "get/2 returns empty string given invalid versions" do
    assert Diff.get("x.x.x", "y") == ""
  end

  test "get/2 returns diff given valid versions" do
    assert Diff.get("1.2.0", "1.2.1") =~ "diff --git config/prod.exs config/prod.exs"
  end
end
