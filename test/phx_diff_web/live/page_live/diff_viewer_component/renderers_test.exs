defmodule PhxDiffWeb.PageLive.DiffViewerComponent.RenderersTest do
  use ExUnit.Case, async: true

  alias PhxDiffWeb.PageLive.DiffViewerComponent.Renderers

  @arrow_symbol "→"

  describe "file_header/2" do
    test "when both names are identical" do
      assert Renderers.filename_diff("apps/foo.css", "apps/foo.css") == "apps/foo.css"
    end

    test "where paths are blank" do
      assert Renderers.filename_diff("", "") == ""
    end

    test "when paths have matching prefixes" do
      assert Renderers.filename_diff("lib/sample_app.ex", "lib/my_app.ex") ==
               "lib/{sample_app.ex #{@arrow_symbol} my_app.ex}"
    end

    test "where paths overlap" do
      assert Renderers.filename_diff("mix.exs", "mix.exs/mix.exs") ==
               "mix.exs #{@arrow_symbol} mix.exs/mix.exs"
    end

    test "when only the suffix matches" do
      assert Renderers.filename_diff("lib/sample_app.ex", "apps/sample_app/lib/sample_app.ex") ==
               "lib/sample_app.ex #{@arrow_symbol} apps/sample_app/lib/sample_app.ex"
    end

    test "when there are both matching prefixes and suffixes" do
      assert Renderers.filename_diff(
               "apps/my_app/lib/my_app/application.ex",
               "apps/sample_app/lib/sample_app/application.ex"
             ) ==
               "apps/{my_app/lib/my_app #{@arrow_symbol} sample_app/lib/sample_app}/application.ex"
    end

    test "when there are no matches in a filename" do
      assert Renderers.filename_diff("foo.ex", "bar.ex") ==
               "foo.ex #{@arrow_symbol} bar.ex"
    end
  end
end
