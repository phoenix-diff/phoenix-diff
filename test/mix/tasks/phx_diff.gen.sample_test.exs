defmodule Mix.Tasks.PhxDiff.Gen.SampleTest do
  use ExUnit.Case, async: true

  alias Mix.Tasks.PhxDiff.Gen
  alias PhxDiff.Diffs.AppSpecification

  test "the appropriate diff is returned after generating 2 versions of an app" do
    Gen.Sample.run(["1.5.2"])

    assert_receive {:mix_shell, :info, [msg]}

    assert msg == """

           Successfully generated sample app.

           To add this to version control, run:

               git add data/sample-app/1.5.2
               git add -f data/sample-app/1.5.2/config/prod.secret.exs
           """

    Gen.Sample.run(["1.5.3"])

    assert {:ok, diff} =
             PhxDiff.Diffs.get_diff(AppSpecification.new("1.5.2"), AppSpecification.new("1.5.3"))

    assert diff =~
             """
             @@ -33,11 +33,11 @@
                # Type `mix help deps` for examples and options.
                defp deps do
                  [
             -      {:phoenix, "~> 1.5.2"},
             +      {:phoenix, "~> 1.5.3"},
                    {:phoenix_ecto, "~> 4.1"},
                    {:ecto_sql, "~> 3.4"},
                    {:postgrex, ">= 0.0.0"},
             -      {:phoenix_live_view, "~> 0.12.0"},
             +      {:phoenix_live_view, "~> 0.13.0"},
                    {:floki, ">= 0.0.0", only: :test},
                    {:phoenix_html, "~> 2.11"},
                    {:phoenix_live_reload, "~> 1.2", only: :dev},
             """
  end

  test "errors with an invalid version id" do
    Gen.Sample.run(["not_a_version"])

    assert_receive {:mix_shell, :error, [msg]}

    assert msg == "Invalid version: \"not_a_version\""
  end

  test "errors when a phoenix version isn't specified" do
    Gen.Sample.run([])

    assert_receive {:mix_shell, :error, [msg]}

    assert msg == "A phoenix version must be specified"
  end
end
