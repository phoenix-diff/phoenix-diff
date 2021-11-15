defmodule Mix.Tasks.PhxDiff.Gen.SampleTest do
  use ExUnit.Case, async: true

  alias Mix.Tasks.PhxDiff.Gen
  alias PhxDiff.Diffs
  alias PhxDiff.TestSupport.DiffFixtures

  test "outputs the appropriate instructions after generating an app" do
    Gen.Sample.run(["1.5.2"])

    assert_receive {:mix_shell, :info, [msg]}

    assert msg == """

           Successfully generated sample app.

           To add this to version control, run:

               git add data/sample-app/1.5.2
               git add -f data/sample-app/1.5.2/config/prod.secret.exs
           """
  end

  @diffs_to_compare [
    {"1.4.16", "1.4.17"},
    {"1.5.2", "1.5.3"},
    {"1.6.0-rc.1", "1.6.0"}
  ]

  describe "diff generation" do
    for {version_1, version_2} <- @diffs_to_compare do
      test "returns known diff comparing #{version_1} to #{version_2}" do
        Gen.Sample.run([unquote(version_1)])
        Gen.Sample.run([unquote(version_2)])

        assert {:ok, diff} =
                 Diffs.get_diff(
                   Diffs.fetch_default_app_specification!(unquote(version_1)),
                   Diffs.fetch_default_app_specification!(unquote(version_2))
                 )

        assert diff == DiffFixtures.known_diff_for!(unquote(version_1), unquote(version_2))
      end
    end
  end

  test "errors with an invalid version id" do
    Gen.Sample.run(["not_a_version"])

    assert_receive {:mix_shell, :error, [msg]}

    assert msg == ~s|Invalid version: \"not_a_version\"|
  end

  test "errors with an unknown version" do
    Gen.Sample.run(["0.1.10"])

    assert_receive {:mix_shell, :error, [msg]}

    assert msg =~ ~s|Unknown version: "0.1.10"|
  end

  test "errors when a phoenix version isn't specified" do
    Gen.Sample.run([])

    assert_receive {:mix_shell, :error, [msg]}

    assert msg == "A phoenix version must be specified"
  end
end
