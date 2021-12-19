defmodule PhxDiffWeb.PageLiveTest do
  use PhxDiffWeb.ConnCase

  import Phoenix.LiveViewTest

  alias PhxDiff.Diffs

  test "redirects to include the source and target in url", %{conn: conn} do
    {:ok, view, _html} =
      conn
      |> live(Routes.page_path(conn, :index))
      |> follow_redirect(
        conn,
        Routes.page_path(conn, :index,
          source: Diffs.previous_release_version(),
          target: Diffs.latest_version()
        )
      )

    assert has_element?(
             view,
             ~S|#[name="diff_selection[source]"] [selected=selected]|,
             Diffs.previous_release_version() |> to_string()
           )

    assert has_element?(
             view,
             ~S|#[name="diff_selection[target]"] [selected=selected]|,
             Diffs.latest_version() |> to_string()
           )

    view
    |> render_change("diff-changed", %{
      "diff_selection" => %{"source" => "1.5.0", "target" => "1.5.1"}
    })

    assert_patched(view, Routes.page_path(conn, :index, source: "1.5.0", target: "1.5.1"))
    assert page_title(view) =~ "v1.5.0 to v1.5.1"

    assert_diff_rendered(view, """
    diff -ruN mix.exs mix.exs
    --- mix.exs	2020-06-10 22:25:39.565354425 -0600
    +++ mix.exs	2020-06-26 21:14:25.000000000 -0600
    @@ -33,7 +33,7 @@
       # Type `mix help deps` for examples and options.
       defp deps do
         [
    -      {:phoenix, "~> 1.5.0"},
    +      {:phoenix, "~> 1.5.1"},
           {:phoenix_ecto, "~> 4.1"},
           {:ecto_sql, "~> 3.4"},
           {:postgrex, ">= 0.0.0"},
    """)
  end

  test "toggling line by line or side by side", %{conn: conn} do
    {:ok, view, _html} =
      conn
      |> live(Routes.page_path(conn, :index))
      |> follow_redirect(conn)

    assert display_mode_button_active?(view, "Line by line")
    refute display_mode_button_active?(view, "Side by side")
    assert diff_results_container_display_mode(view) == "line-by-line"

    view
    |> element("#diff-viewer-form-main-diff")
    |> render_change(%{"form" => %{"view_type" => "side-by-side"}})

    refute display_mode_button_active?(view, "Line by line")
    assert display_mode_button_active?(view, "Side by side")
    assert diff_results_container_display_mode(view) == "side-by-side"

    view
    |> element("#diff-viewer-form-main-diff")
    |> render_change(%{"form" => %{"view_type" => "line-by-line"}})

    assert display_mode_button_active?(view, "Line by line")
    refute display_mode_button_active?(view, "Side by side")
    assert diff_results_container_display_mode(view) == "line-by-line"
  end

  test "falls back to latest version when target url_param is invalid", %{conn: conn} do
    {:ok, _view, _html} =
      conn
      |> live(
        Routes.page_path(conn, :index, source: Diffs.previous_release_version(), target: "invalid")
      )
      |> follow_redirect(
        conn,
        Routes.page_path(conn, :index,
          source: Diffs.previous_release_version(),
          target: Diffs.latest_version()
        )
      )
  end

  test "falls back to previous version when source url_param is invalid", %{conn: conn} do
    {:ok, _view, _html} =
      conn
      |> live(Routes.page_path(conn, :index, source: "invalid", target: Diffs.latest_version()))
      |> follow_redirect(
        conn,
        Routes.page_path(conn, :index,
          source: Diffs.previous_release_version(),
          target: Diffs.latest_version()
        )
      )
  end

  @version_with_live_default_option "1.5.0"
  @version_without_live_default_option "1.4.0"

  test "indicates the options used to generate the source and target apps", %{conn: conn} do
    {:ok, view, _html} =
      conn
      |> live(Routes.page_path(conn, :index))
      |> follow_redirect(conn)

    view
    |> element("#diff-selector-form")
    |> render_change(%{
      "diff_selection" => %{
        "source" => @version_with_live_default_option,
        "target" => @version_without_live_default_option
      }
    })

    assert view
           |> element(".version-selector-source")
           |> render() =~ "Generated with --live"

    refute view
           |> element(".version-selector-target")
           |> render() =~ "Generated with --live"

    view
    |> element("#diff-selector-form")
    |> render_change(%{
      "diff_selection" => %{
        "source" => @version_without_live_default_option,
        "target" => @version_with_live_default_option
      }
    })

    refute view
           |> element(".version-selector-source")
           |> render() =~ "Generated with --live"

    assert view
           |> element(".version-selector-target")
           |> render() =~ "Generated with --live"
  end

  defp assert_diff_rendered(view, expected_diff) do
    diff_from_view =
      element(view, ".diff-results-container")
      |> render()
      |> Floki.parse_fragment!()
      |> Floki.attribute("data-diff")
      |> List.first()

    assert strip_date_from_diff(diff_from_view) ==
             strip_date_from_diff(expected_diff)
  end

  defp diff_results_container_display_mode(view) do
    element(view, ".diff-results-container")
    |> render()
    |> Floki.parse_fragment!()
    |> Floki.attribute("data-view-type")
    |> List.first()
  end

  defp display_mode_button_active?(view, button_text) do
    has_element?(view, "#diff-view-toggles .btn.active", button_text)
  end

  defp strip_date_from_diff(diff) do
    Regex.replace(~r/([+\-]{3} [^\t]+)\t(.*)/, diff, "\\1")
  end
end
