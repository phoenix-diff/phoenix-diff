defmodule PhxDiffWeb.CompareLiveTest do
  use PhxDiffWeb.ConnCase

  import Phoenix.LiveViewTest
  import PhxDiff.TestSupport.OpenTelemetryTestExporter, only: [subscribe_to_otel_spans: 1]
  import PhxDiff.TestSupport.Sigils
  import PhxDiff.CaptureJSONLog

  alias PhxDiff.AppSpecification
  alias PhxDiff.TestSupport.DiffFixtures

  setup [:subscribe_to_otel_spans]

  test "interacting with diff form", %{conn: conn} do
    {:ok, view, _html} = conn |> live(~p"/compare/1.7.1...1.7.2")

    form_data = get_form_data(view)

    assert form_data.source.version == "1.7.1"
    assert form_data.source.variant == "default"
    assert form_data.target.version == "1.7.2"
    assert form_data.target.variant == "default"

    view
    |> element("#diff-selection-form")
    |> render_change(%{
      "diff_selection" => %{
        "source" => %{"version" => "1.5.0"},
        "target" => %{"version" => "1.5.1"}
      }
    })

    assert_patch(
      view,
      ~p"/compare/1.5.0 --live...1.5.1 --live"
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
                      name: "PhxDiffWeb.CompareLive.mount",
                      attributes: %{"liveview.callback": "mount"}
                    }}
  end

  test "returns 404 with an invalid diff spec", %{conn: conn} do
    assert_error_sent(404, fn ->
      get(conn, ~p"/compare/invalid")
    end)
  end

  test "toggling line by line or side by side", %{conn: conn} do
    {:ok, view, _html} = conn |> live(~p"/compare/1.7.1...1.7.2")

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

  test "indicates no changes for identical versions", %{conn: conn} do
    {:ok, _view, html} =
      live(
        conn,
        ~p"/compare/1.5.9...1.5.9"
      )

    assert html =~ "no changes"
  end

  test "allows comparing variants of the same version", %{conn: conn} do
    {:ok, view, _html} =
      conn
      |> live(~p"/compare/1.5.9...1.5.9 --live")

    assert_diff_rendered(
      view,
      DiffFixtures.known_diff_for!(
        AppSpecification.new(~V|1.5.9|, []),
        AppSpecification.new(~V|1.5.9|, ["--live"])
      )
    )

    {:ok, view, _html} =
      conn
      |> live(~p"/compare/1.7.0-rc.0 --no-ecto...1.7.0-rc.0")

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
      |> live(~p"/compare/1.7.1...1.7.2")

    mix_exs_file_list_element =
      view
      |> element(
        ".file-list li",
        "mix.exs"
      )
      |> render()

    assert mix_exs_file_list_element =~
             "#d2h-008078"

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
             "#d2h-487262"

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
          |> live(~p"/compare/1.5.9...1.5.9 --live")
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

  defp get_form_data(view) do
    document =
      view
      |> render()
      |> Floki.parse_document!()

    %{
      source: %{
        version:
          Floki.attribute(
            document,
            ~S|#[name="diff_selection[source][version]"] [selected=selected]|,
            "value"
          )
          |> List.first(),
        variant:
          Floki.attribute(
            document,
            ~S|#[name="diff_selection[source][variant]"] [selected=selected]|,
            "value"
          )
          |> List.first()
      },
      target: %{
        version:
          Floki.attribute(
            document,
            ~S|#[name="diff_selection[target][version]"] [selected=selected]|,
            "value"
          )
          |> List.first(),
        variant:
          Floki.attribute(
            document,
            ~S|#[name="diff_selection[target][variant]"] [selected=selected]|,
            "value"
          )
          |> List.first()
      }
    }
  end
end
