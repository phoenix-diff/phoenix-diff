defmodule PhxDiffWeb.PageLiveTest do
  use PhxDiffWeb.ConnCase

  import Phoenix.LiveViewTest
  import PhxDiff.TestSupport.OpenTelemetryTestExporter, only: [subscribe_to_otel_spans: 1]
  import PhxDiff.TestSupport.Sigils
  import PhxDiff.CaptureJSONLog

  alias PhxDiff.AppSpecification
  alias PhxDiff.TestSupport.DiffFixtures

  setup [:subscribe_to_otel_spans]

  test "redirects to include the source and target in url", %{conn: conn} do
    {:ok, view, _html} =
      conn
      |> live(~p"/")
      |> follow_redirect(
        conn,
        ~p"/?source=#{PhxDiff.previous_release_version()}&target=#{PhxDiff.latest_version()}"
      )

    assert has_element?(
             view,
             ~S|#[name="diff_selection[source]"] [selected=selected]|,
             PhxDiff.previous_release_version() |> to_string()
           )

    assert has_element?(
             view,
             ~S|#[name="diff_selection[target]"] [selected=selected]|,
             PhxDiff.latest_version() |> to_string()
           )

    view
    |> render_change("diff-changed", %{
      "diff_selection" => %{"source" => "1.5.0", "target" => "1.5.1"}
    })

    assert_patched(view, ~p"/?source=1.5.0&target=1.5.1")
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

    assert_receive {:otel_span,
                    %{
                      instrumentation_scope: %{name: "opentelemetry_phoenix"},
                      attributes: %{"http.status_code": 200}
                    }}

    assert_receive {:otel_span,
                    %{
                      name: :"PhxDiff.Diffs.get_diff/3",
                      attributes: %{
                        "diff.source_phoenix_version": "1.5.0",
                        "diff.target_phoenix_version": "1.5.1"
                      }
                    } = diff_span}

    assert %{name: "phx_diff"} = diff_span.instrumentation_scope

    assert_receive {:otel_span,
                    %{
                      instrumentation_scope: %{name: "opentelemetry_liveview"},
                      name: "PhxDiffWeb.PageLive.mount",
                      attributes: %{"liveview.callback": "mount"}
                    }}
  end

  test "toggling line by line or side by side", %{conn: conn} do
    {:ok, view, _html} =
      conn
      |> live(~p"/")
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
      |> live(~p"/?source=#{PhxDiff.previous_release_version()}&target=invalid")
      |> follow_redirect(
        conn,
        ~p"/?source=#{PhxDiff.previous_release_version()}&target=#{PhxDiff.latest_version()}"
      )
  end

  test "falls back to previous version when source url_param is invalid", %{conn: conn} do
    {:ok, _view, _html} =
      conn
      |> live(~p"/?source=invalid&target=#{PhxDiff.latest_version()}")
      |> follow_redirect(
        conn,
        ~p"/?source=#{PhxDiff.previous_release_version()}&target=#{PhxDiff.latest_version()}"
      )
  end

  @unknown_phoenix_version "0.0.99"

  test "falls back to latest version when target url_param is unknown", %{conn: conn} do
    {:ok, _view, _html} =
      conn
      |> live(
        ~p"/?source=#{PhxDiff.previous_release_version()}&target=#{@unknown_phoenix_version}"
      )
      |> follow_redirect(
        conn,
        ~p"/?source=#{PhxDiff.previous_release_version()}&target=#{PhxDiff.latest_version()}"
      )
  end

  test "falls back to previous version when source url_param is unknown", %{conn: conn} do
    {:ok, _view, _html} =
      conn
      |> live(~p"/?source=#{@unknown_phoenix_version}&target=#{PhxDiff.latest_version()}")
      |> follow_redirect(
        conn,
        ~p"/?source=#{PhxDiff.previous_release_version()}&target=#{PhxDiff.latest_version()}"
      )

    assert_received {:otel_span,
                     %{
                       instrumentation_scope: %{name: "opentelemetry_phoenix"},
                       attributes: %{"http.status_code": 302}
                     }}
  end

  @version_with_live_default_option "1.5.0"
  @version_without_live_default_option "1.4.0"

  test "indicates the options used to generate the source and target apps", %{conn: conn} do
    {:ok, view, _html} =
      conn
      |> live(~p"/")
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
           |> element("#source-selector")
           |> render() =~ "Generated with --live"

    refute view
           |> element("#target-selector")
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
           |> element("#source-selector")
           |> render() =~ "Generated with --live"

    assert view
           |> element("#target-selector")
           |> render() =~ "Generated with --live"
  end

  test "allows comparing variants of the same version", %{conn: conn} do
    {:ok, view, _html} =
      conn
      |> live(~p"/?source=1.5.9&source_variant=default&target=1.5.9&target_variant=live")

    assert_diff_rendered(
      view,
      DiffFixtures.known_diff_for!(
        AppSpecification.new(~V|1.5.9|, []),
        AppSpecification.new(~V|1.5.9|, ["--live"])
      )
    )

    {:ok, view, _html} =
      conn
      |> live(~p"/?source=1.7.0-rc.0&source_variant=no-ecto&target=1.7.0-rc.0")

    assert_diff_rendered(
      view,
      DiffFixtures.known_diff_for!(
        AppSpecification.new(~V|1.7.0-rc.0|, ["--no-ecto"]),
        AppSpecification.new(~V|1.7.0-rc.0|, [])
      )
    )
  end

  test "generates logs with appropriate metadata attached", %{conn: conn} do
    diff_logs =
      capture_json_log(fn ->
        {:ok, _view, _html} =
          conn
          |> live(~p"/?source=1.5.9&source_variant=default&target=1.5.9&target_variant=live")
      end)
      |> Enum.filter(&match?(%{"event.domain" => "diffs"}, &1))

    assert compare_log =
             Enum.find(diff_logs, &match?(%{"message" => ~S|Comparing "1.5.9" to "1.5.9"|}, &1))

    assert is_binary(compare_log["trace.id"])
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
    has_element?(view, "#diff-view-toggles input:checked + label", button_text)
  end

  defp strip_date_from_diff(diff) do
    Regex.replace(~r/([+\-]{3} [^\t]+)\t(.*)/, diff, "\\1")
  end
end
