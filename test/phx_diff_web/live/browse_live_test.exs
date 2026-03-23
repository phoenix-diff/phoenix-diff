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
  end
end
