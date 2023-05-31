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
    {:ok, view, _html} = conn |> live(~p"/") |> follow_redirect(conn)

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
    |> element("#diff-selection-form")
    |> render_change(%{"diff_selection" => %{"source" => "1.5.0", "target" => "1.5.1"}})

    assert_patch(
      view,
      ~p"/?#{[source: ~V|1.5.0|, source_variant: :live, target: ~V|1.5.1|, target_variant: :live]}"
    )

    assert page_title(view) =~ "v1.5.0 to v1.5.1"

    assert_diff_rendered(
      view,
      DiffFixtures.known_diff_for!(
        AppSpecification.new(~V|1.5.0|, ["--live"]),
        AppSpecification.new(~V|1.5.1|, ["--live"])
      )
    )

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
    {:ok, view, _html} = conn |> live(~p"/") |> follow_redirect(conn)

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
        ~p"/?#{[source: PhxDiff.previous_release_version(), source_variant: :default, target: PhxDiff.latest_version(), target_variant: :default]}"
      )
  end

  test "falls back to previous version when source url_param is invalid", %{conn: conn} do
    {:ok, _view, _html} =
      conn
      |> live(~p"/?source=invalid&target=#{PhxDiff.latest_version()}")
      |> follow_redirect(
        conn,
        ~p"/?#{[source: PhxDiff.previous_release_version(), source_variant: :default, target: PhxDiff.latest_version(), target_variant: :default]}"
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
        ~p"/?#{[source: PhxDiff.previous_release_version(), source_variant: :default, target: PhxDiff.latest_version(), target_variant: :default]}"
      )
  end

  test "falls back to previous version when source url_param is unknown", %{conn: conn} do
    {:ok, _view, _html} =
      conn
      |> live(~p"/?source=#{@unknown_phoenix_version}&target=#{PhxDiff.latest_version()}")
      |> follow_redirect(
        conn,
        ~p"/?#{[source: PhxDiff.previous_release_version(), source_variant: :default, target: PhxDiff.latest_version(), target_variant: :default]}"
      )

    assert_received {:otel_span,
                     %{
                       instrumentation_scope: %{name: "opentelemetry_phoenix"},
                       attributes: %{"http.status_code": 302}
                     }}
  end

  test "indicates no changes for identical versions", %{conn: conn} do
    {:ok, _view, html} =
      live(
        conn,
        ~p"/?#{[source: ~V|1.5.9|, source_variant: :default, target: ~V|1.5.9|, target_variant: :default]}"
      )

    assert html =~ "no changes"
  end

  test "allows comparing variants of the same version", %{conn: conn} do
    {:ok, view, _html} =
      conn
      |> live(
        ~p"/?#{[source: ~V|1.5.9|, source_variant: :default, target: ~V|1.5.9|, target_variant: :live]}"
      )

    assert_diff_rendered(
      view,
      DiffFixtures.known_diff_for!(
        AppSpecification.new(~V|1.5.9|, []),
        AppSpecification.new(~V|1.5.9|, ["--live"])
      )
    )

    {:ok, view, _html} =
      conn
      |> live(
        ~p"/?#{[source: ~V|1.7.0-rc.0|, source_variant: :no_ecto, target: ~V|1.7.0-rc.0|, target_variant: :default]}"
      )

    assert_diff_rendered(
      view,
      DiffFixtures.known_diff_for!(
        AppSpecification.new(~V|1.7.0-rc.0|, ["--no-ecto"]),
        AppSpecification.new(~V|1.7.0-rc.0|, [])
      )
    )
  end

  @arrow_symbol "→"

  test "displays the file list in a diff2html compatible format", %{conn: conn} do
    {:ok, view, _html} =
      conn
      |> live(
        ~p"/?#{[source: ~V|1.7.1|, source_variant: :default, target: ~V|1.7.2|, target_variant: :default]}"
      )

    mix_exs_file_list_element =
      view
      |> element(
        ".file-list li",
        "mix.exs"
      )
      |> render()

    assert mix_exs_file_list_element =~
             "/?source=1.7.1&amp;source_variant=default&amp;target=1.7.2&amp;target_variant=default#d2h-008078"

    assert mix_exs_file_list_element =~ "Changed"
    assert mix_exs_file_list_element =~ "+3"
    assert mix_exs_file_list_element =~ "-3"

    xmark_file_list_element =
      view
      |> element(
        ".file-list li",
        "{priv/hero_icons #{@arrow_symbol} assets/vendor/heroicons}/optimized/24/solid/x-mark.svg"
      )
      |> render()

    assert xmark_file_list_element =~
             "/?source=1.7.1&amp;source_variant=default&amp;target=1.7.2&amp;target_variant=default#d2h-487262"

    assert xmark_file_list_element =~ "Renamed"
    assert xmark_file_list_element =~ "+0"
    assert xmark_file_list_element =~ "-0"

    academic_cap_file_list_element =
      view
      |> element(
        ".file-list li",
        "{priv/hero_icons → assets/vendor/heroicons}/optimized/20/solid/academic-cap.svg"
      )
      |> render()

    assert academic_cap_file_list_element =~ "#d2h-289300"
    assert academic_cap_file_list_element =~ "Renamed"
    assert academic_cap_file_list_element =~ "+0"
    assert academic_cap_file_list_element =~ "-0"

    assert priv_upgrade_md_element =
             view
             |> element(
               ".file-list li",
               "priv/hero_icons/UPGRADE.md"
             )
             |> render()

    assert priv_upgrade_md_element =~ "d2h-294307"
    assert priv_upgrade_md_element =~ "Removed"
    assert priv_upgrade_md_element =~ "+0"
    assert priv_upgrade_md_element =~ "-7"

    assert logo_svg_element =
             view
             |> element(
               ".file-list li",
               "priv/static/images/logo.svg"
             )
             |> render()

    assert logo_svg_element =~ "d2h-470697"
    assert logo_svg_element =~ "Added"
    assert logo_svg_element =~ "+6"
    assert logo_svg_element =~ "-0"
  end

  test "generates logs with appropriate metadata attached", %{conn: conn} do
    diff_logs =
      capture_json_log(fn ->
        {:ok, _view, _html} =
          conn
          |> live(
            ~p"/?#{[source: ~V|1.5.9|, source_variant: :default, target: ~V|1.5.9|, target_variant: :live]}"
          )
      end)
      |> Enum.filter(&match?(%{"event.domain" => "diffs"}, &1))

    assert compare_log =
             Enum.find(
               diff_logs,
               &match?(%{"message" => ~S|Comparing "1.5.9" to "1.5.9 --live"|}, &1)
             )

    assert compare_log["event.name"] == "compare.start"
    assert compare_log["phx_diff.comparison.source_version"] == "1.5.9"
    assert compare_log["phx_diff.comparison.source_phx_new_arguments"] == ""
    assert compare_log["phx_diff.comparison.target_version"] == "1.5.9"
    assert compare_log["phx_diff.comparison.target_phx_new_arguments"] == "--live"
    assert is_binary(compare_log["trace.id"])
  end

  defp assert_diff_rendered(view, expected_diff) do
    diff_from_view =
      element(view, ".diff-results-container")
      |> render()
      |> Floki.parse_fragment!()
      |> Floki.attribute("data-diff")
      |> List.first()

    assert diff_from_view == expected_diff
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
end
