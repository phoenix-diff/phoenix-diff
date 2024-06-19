defmodule PhxDiffWeb.PageControllerTest do
  use PhxDiffWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Mox

  describe "GET /" do
    test "redirects to /compare/<prev>...<latest> when no params", %{conn: conn} do
      path =
        conn
        |> get(~p"/")
        |> redirected_to(:found)

      {:ok, view, _html} = conn |> live(path)

      form_data = get_form_data(view)

      assert form_data.source.version == PhxDiff.previous_release_version() |> to_string()
      assert form_data.source.variant == "default"
      assert form_data.target.version == PhxDiff.latest_version() |> to_string()
      assert form_data.target.variant == "default"
    end

    test "falls back to latest version when target is invalid", %{conn: conn} do
      path =
        conn
        |> get(~p"/?source=1.7.2&target=invalid")
        |> redirected_to(:moved_permanently)

      {:ok, view, _html} = live(conn, path)

      form_data = get_form_data(view)

      assert form_data.source.version == "1.7.2"
      assert form_data.source.variant == "default"
      assert form_data.target.version == PhxDiff.latest_version() |> to_string()
      assert form_data.target.variant == "default"
    end

    test "falls back to previous version when source is invalid", %{conn: conn} do
      path =
        conn
        |> get(~p"/?source=invalid&target=1.7.2")
        |> redirected_to(:moved_permanently)

      {:ok, view, _html} = live(conn, path)

      form_data = get_form_data(view)

      assert form_data.source.version == PhxDiff.previous_release_version() |> to_string()
      assert form_data.source.variant == "default"
      assert form_data.target.version == "1.7.2"
      assert form_data.target.variant == "default"
    end

    @unknown_phoenix_version "0.0.99"
    test "falls back to latest version when target url_param is unknown", %{conn: conn} do
      path =
        conn
        |> get(~p"/?source=1.7.1&target=#{@unknown_phoenix_version}")
        |> redirected_to(:moved_permanently)

      {:ok, view, _html} = live(conn, path)

      form_data = get_form_data(view)

      assert form_data.source.version == "1.7.1"
      assert form_data.source.variant == "default"
      assert form_data.target.version == PhxDiff.latest_version() |> to_string()
      assert form_data.target.variant == "default"
    end

    test "falls back to previous version when source url_param is unknown", %{conn: conn} do
      path =
        conn
        |> get(~p"/?source=#{@unknown_phoenix_version}&target=1.7.1")
        |> redirected_to(:moved_permanently)

      {:ok, view, _html} = live(conn, path)

      form_data = get_form_data(view)

      assert form_data.source.version == PhxDiff.previous_release_version() |> to_string()
      assert form_data.source.variant == "default"
      assert form_data.target.version == "1.7.1"
      assert form_data.target.variant == "default"
    end

    test "passes through variants", %{conn: conn} do
      path =
        conn
        |> get(~p"/?source=1.7.1&source_variant=no_ecto&target=1.7.1&target_variant=umbrella")
        |> redirected_to(:moved_permanently)

      {:ok, view, _html} = live(conn, path)

      form_data = get_form_data(view)

      assert form_data.source.version == "1.7.1"
      assert form_data.source.variant == "no_ecto"
      assert form_data.target.version == "1.7.1"
      assert form_data.target.variant == "umbrella"
    end

    test "redirects to default variants when variants are invalid", %{conn: conn} do
      path =
        conn
        |> get(~p"/?source=1.7.1&source_variant=invalid&target=1.7.1&target_variant=invalid")
        |> redirected_to(:moved_permanently)

      {:ok, view, _html} = live(conn, path)

      form_data = get_form_data(view)

      assert form_data.source.version == "1.7.1"
      assert form_data.source.variant == "default"
      assert form_data.target.version == "1.7.1"
      assert form_data.target.variant == "default"
    end
  end

  describe "GET /compare" do
    test "redirects to /compare/<prev>...<latest>", %{conn: conn} do
      path =
        conn
        |> get(~p"/compare")
        |> redirected_to(:found)

      {:ok, view, _html} = conn |> live(path)

      form_data = get_form_data(view)

      assert form_data.source.version == PhxDiff.previous_release_version() |> to_string()
      assert form_data.source.variant == "default"
      assert form_data.target.version == PhxDiff.latest_version() |> to_string()
      assert form_data.target.variant == "default"
    end

    @tag :tmp_dir
    test "redirects to first available version when default version is unavailable", %{
      conn: conn,
      tmp_dir: tmp_dir
    } do
      tmp_repo_path = Path.join(tmp_dir, "app_repo")
      stub(PhxDiff.Config.Mock, :app_repo_path, fn -> tmp_repo_path end)

      # The 1.5 series defaults to --live, but if we don't have --live generate, we still want to view the diff
      tmp_repo_path |> Path.join("1.5.3/default") |> File.mkdir_p!()
      tmp_repo_path |> Path.join("1.5.4/binary-id") |> File.mkdir_p!()
      tmp_repo_path |> Path.join("1.5.4/default") |> File.mkdir_p!()
      tmp_repo_path |> Path.join("1.5.4/no-ecto") |> File.mkdir_p!()

      path =
        conn
        |> get(~p"/compare")
        |> redirected_to(:found)

      {:ok, view, _html} = conn |> live(path)

      form_data = get_form_data(view)

      assert form_data.source.version == "1.5.3"
      assert form_data.source.variant == "default"
      assert form_data.target.version == "1.5.4"
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
