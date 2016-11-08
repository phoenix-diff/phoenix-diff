defmodule PhoenixDiff.WellKnownLocationsControllerTest do
  use PhoenixDiff.ConnCase, async: true

  test "GET acme_challenge renders the acme challenge secret with the key is valid", %{conn: conn} do
    conn = conn |> get("/.well-known/acme-challenge/ACME-CHALLENGE-KEY")

    assert text_response(conn, 200) == "ACME-CHALLENGE-SECRET"
  end

  test "GET acme_challenge renders 404 when the key is invalid", %{conn: conn} do
    conn = conn |> get("/.well-known/acme-challenge/invalid-key")

    assert text_response(conn, 404) == "Invalid key"
  end
end
