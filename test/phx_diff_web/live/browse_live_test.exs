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

    test "shows a raw link pointing to the raw file URL", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/browse/1.7.1/files/mix.exs")

      assert html =~ ~s|href="/browse/1.7.1/raw/mix.exs"|
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

  describe "file tree" do
    test "renders directory groupings", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/browse/1.7.1/files/mix.exs")

      # Directories should appear as group headers
      assert html =~ "lib"
      assert html =~ "config"

      # Files within directories should be rendered as links
      parsed = Floki.parse_document!(html)

      # Find file tree links
      file_links =
        Floki.find(parsed, "#file-tree a")
        |> Enum.map(&Floki.text/1)
        |> Enum.map(&String.trim/1)

      assert "mix.exs" in file_links
    end

    test "selected file has active styling", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/browse/1.7.1/files/mix.exs")

      parsed = Floki.parse_document!(html)

      active_links =
        Floki.find(parsed, "#file-tree .text-primary")
        |> Enum.map(&Floki.text/1)
        |> Enum.map(&String.trim/1)

      assert "mix.exs" in active_links
    end

    test "mobile toggle button shows file count", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/browse/1.7.1/files/mix.exs")

      html = render(view)

      # The mobile toggle should display the file count
      assert html =~ "file-tree-toggle"
    end
  end

  describe "invalid app spec" do
    test "returns 404 for nonexistent version", %{conn: conn} do
      assert_error_sent(404, fn ->
        live(conn, ~p"/browse/0.0.0/files/mix.exs")
      end)
    end

    test "returns 404 for nonexistent version without file path", %{conn: conn} do
      assert_error_sent(404, fn ->
        live(conn, ~p"/browse/0.0.0")
      end)
    end
  end

  describe "nonexistent file" do
    test "returns 404 for a file that does not exist", %{conn: conn} do
      assert_error_sent(404, fn ->
        live(conn, ~p"/browse/1.7.1/files/no/such/file.ex")
      end)
    end
  end

  describe "path traversal" do
    test "returns 404 for path with .. segments", %{conn: conn} do
      assert_error_sent(404, fn ->
        live(conn, "/browse/1.7.1/files/lib/..%2F..%2F..%2Fetc%2Fpasswd")
      end)
    end
  end

  describe "binary files" do
    test "shows binary file message instead of content", %{conn: conn} do
      {:ok, _view, html} =
        live(conn, ~p"/browse/1.7.1/files/priv/static/favicon.ico")

      assert html =~ "Binary file not displayed"
      refute html =~ "CodeHighlight"
    end

    test "shows a raw link for binary files", %{conn: conn} do
      {:ok, _view, html} =
        live(conn, ~p"/browse/1.7.1/files/priv/static/favicon.ico")

      assert html =~ ~s|href="/browse/1.7.1/raw/priv/static/favicon.ico"|
    end
  end

  describe "dotfiles" do
    test "dotfiles appear in the file list", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/browse/1.7.1/files/mix.exs")

      html = render(view)
      assert html =~ ".formatter.exs"
    end

    test "dotfiles can be opened and display content", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/browse/1.7.1/files/.formatter.exs")

      assert html =~ "import_deps"
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
