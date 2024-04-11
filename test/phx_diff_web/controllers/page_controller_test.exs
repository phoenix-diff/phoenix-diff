defmodule PhxDiffWeb.PageControllerTest do
  use PhxDiffWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "GET /" do
    test "redirects to /compare/<prev>...<latest> when no params", %{conn: conn} do
      path =
        conn
        |> get(~p"/")
        |> redirected_to()

      {:ok, view, _html} = conn |> live(path)

      form_data = get_form_data(view)

      assert form_data.source.version == PhxDiff.previous_release_version() |> to_string()
      assert form_data.source.variant == "default"
      assert form_data.target.version == PhxDiff.latest_version() |> to_string()
      assert form_data.target.variant == "default"
    end

    test "falls back to latest version when target is invalid", %{conn: conn} do
      {:ok, conn} =
        conn
        |> live(~p"/?source=1.7.2&target=invalid")
        |> follow_redirect(conn)

      {:ok, view, _html} = live(conn)

      form_data = get_form_data(view)

      assert form_data.source.version == "1.7.2"
      assert form_data.source.variant == "default"
      assert form_data.target.version == PhxDiff.latest_version() |> to_string()
      assert form_data.target.variant == "default"
    end

    test "falls back to previous version when source is invalid", %{conn: conn} do
      {:ok, conn} =
        conn
        |> live(~p"/?source=invalid&target=1.7.2")
        |> follow_redirect(conn)

      {:ok, view, _html} = live(conn)

      form_data = get_form_data(view)

      assert form_data.source.version == PhxDiff.previous_release_version() |> to_string()
      assert form_data.source.variant == "default"
      assert form_data.target.version == "1.7.2"
      assert form_data.target.variant == "default"
    end

    @unknown_phoenix_version "0.0.99"
    test "falls back to latest version when target url_param is unknown", %{conn: conn} do
      {:ok, conn} =
        conn
        |> live(~p"/?source=1.7.1&target=#{@unknown_phoenix_version}")
        |> follow_redirect(conn)

      {:ok, view, _html} = live(conn)

      form_data = get_form_data(view)

      assert form_data.source.version == "1.7.1"
      assert form_data.source.variant == "default"
      assert form_data.target.version == PhxDiff.latest_version() |> to_string()
      assert form_data.target.variant == "default"
    end

    test "falls back to previous version when source url_param is unknown", %{conn: conn} do
      {:ok, conn} =
        conn
        |> live(~p"/?source=#{@unknown_phoenix_version}&target=1.7.1")
        |> follow_redirect(conn)

      {:ok, view, _html} = live(conn)

      form_data = get_form_data(view)

      assert form_data.source.version == PhxDiff.previous_release_version() |> to_string()
      assert form_data.source.variant == "default"
      assert form_data.target.version == "1.7.1"
      assert form_data.target.variant == "default"
    end

    test "passes through variants", %{conn: conn} do
      {:ok, conn} =
        conn
        |> live(~p"/?source=1.7.1&source_variant=no_ecto&target=1.7.1&target_variant=umbrella")
        |> follow_redirect(conn)

      {:ok, view, _html} = live(conn)

      form_data = get_form_data(view)

      assert form_data.source.version == "1.7.1"
      assert form_data.source.variant == "no_ecto"
      assert form_data.target.version == "1.7.1"
      assert form_data.target.variant == "umbrella"
    end

    test "redirects to default variants when variants are invalid", %{conn: conn} do
      {:ok, conn} =
        conn
        |> live(~p"/?source=1.7.1&source_variant=invalid&target=1.7.1&target_variant=invalid")
        |> follow_redirect(conn)

      {:ok, view, _html} = live(conn)

      form_data = get_form_data(view)

      assert form_data.source.version == "1.7.1"
      assert form_data.source.variant == "default"
      assert form_data.target.version == "1.7.1"
      assert form_data.target.variant == "default"
    end
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
