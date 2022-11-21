defmodule Mix.Tasks.PhxDiff.Gen.SampleTest do
  use PhxDiff.MockedConfigCase, async: true

  alias Mix.Tasks.PhxDiff.Gen
  alias PhxDiff.AppSpecification
  alias PhxDiff.TestSupport.DiffFixtures

  test "outputs the appropriate instructions after generating an app" do
    Gen.Sample.run(["1.5.2"])

    assert_receive {:mix_shell, :info, [msg]}

    assert msg == """

           Successfully generated sample app.

           To add this to version control, run:

               git add priv/data/sample-app/1.5.2
               git add -f priv/data/sample-app/1.5.2/config/prod.secret.exs
           """
  end

  @diffs_to_compare [
    {{"1.4.16", []}, {"1.4.17", []}},
    {{"1.5.2", ["--live"]}, {"1.5.3", ["--live"]}},
    {{"1.6.0-rc.1", []}, "1.6.0", []}
  ]

  describe "diff generation" do
    for {{version_1, v1_opts}, {version_2, v2_opts}} <- @diffs_to_compare do
      test "returns known diff comparing #{version_1} #{Enum.join(v1_opts, " ")} to #{version_2} #{Enum.join(v2_opts, " ")}" do
        v1_app_spec =
          AppSpecification.new(
            Version.parse!(unquote(version_1)),
            unquote(v1_opts)
          )

        v2_app_spec =
          AppSpecification.new(
            Version.parse!(unquote(version_2)),
            unquote(v2_opts)
          )

        Gen.Sample.run([unquote(version_1)])
        Gen.Sample.run([unquote(version_2)])

        assert {:ok, diff} = PhxDiff.fetch_diff(v1_app_spec, v2_app_spec)

        assert diff == DiffFixtures.known_diff_for!(v1_app_spec, v2_app_spec)
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
