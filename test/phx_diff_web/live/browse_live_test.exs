defmodule PhxDiffWeb.BrowseLiveTest do
  use PhxDiffWeb.ConnCase

  import Phoenix.LiveViewTest

  describe "browsing an app specification" do
    test "redirects to README.md when present", %{conn: conn} do
      assert {:error, {:live_redirect, %{to: "/browse/1.7.1/files/README.md"}}} =
               live(conn, ~p"/browse/1.7.1")
    end

    test "renders file names in the file list", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/browse/1.7.1/files/README.md")

      html = render(view)
      assert html =~ "mix.exs"
      assert html =~ ".formatter.exs"
    end
  end

  describe "viewing a specific file" do
    test "renders file content", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/browse/1.7.1/files/mix.exs")

      assert html =~ "defmodule"
    end

    test "shows selected file in header", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/browse/1.7.1/files/mix.exs")

      assert html =~ "mix.exs"
    end

    test "applies language class for syntax highlighting", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/browse/1.7.1/files/mix.exs")

      assert html =~ "language-elixir"
      assert html =~ "CodeHighlight"
    end

    test "navigating between files updates content", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/browse/1.7.1/files/mix.exs")

      assert render(view) =~ "defmodule"

      view
      |> element(~s|a[href="/browse/1.7.1/files/README.md"]|)
      |> render_click()

      assert_patch(view, ~p"/browse/1.7.1/files/README.md")
    end
  end

  describe "/browse redirect" do
    test "redirects to the latest version", %{conn: conn} do
      latest_version = PhxDiff.latest_version()

      conn = get(conn, ~p"/browse")

      assert redirected_to(conn) == "/browse/#{latest_version}"
    end
  end

  describe "navigation" do
    test "root layout contains a Browse link", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/browse/1.7.1/files/README.md")

      assert html =~ ~s|href="/browse"|
      assert html =~ "Browse"
    end
  end

  describe "switching app specifications" do
    test "submitting the form with a different version navigates to new app spec", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/browse/1.7.1/files/README.md")

      view
      |> element("#app-selection-form")
      |> render_submit(%{app_selection: %{version: "1.6.0", variant: "default"}})

      assert_patch(view, ~p"/browse/1.6.0/files/README.md")
    end

    test "changing version updates variant options", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/browse/1.7.1/files/README.md")

      html =
        view
        |> element("#app-selection-form")
        |> render_change(%{app_selection: %{version: "1.6.0", variant: "default"}})

      assert html =~ "version"
    end
  end
end
