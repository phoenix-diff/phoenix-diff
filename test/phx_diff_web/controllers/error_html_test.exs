defmodule PhxDiffWeb.ErrorHTMLTest do
  use PhxDiffWeb.ConnCase, async: true

  # Bring render/3 and render_to_string/3 for testing custom views
  import Phoenix.Template

  test "renders 404.html" do
    assert render_to_string(PhxDiffWeb.ErrorHTML, "404", "html", []) == "Not Found"
  end

  test "renders 500.html" do
    assert render_to_string(PhxDiffWeb.ErrorHTML, "500", "html", []) == "Internal Server Error"
  end
end
