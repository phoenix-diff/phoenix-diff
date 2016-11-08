defmodule PhoenixDiff.WellKnownLocationsController do
  use PhoenixDiff.Web, :controller

  def acme_challenge(conn, %{"id" => id}) do
    if id == acme_challenge_key do
      conn |> text(acme_challenge_secret)
    else
      conn |> put_status(:not_found) |> text("Invalid key")
    end
  end

  defp acme_challenge_key, do: System.get_env("ACME_CHALLENGE_KEY") || "ACME-CHALLENGE-KEY"
  defp acme_challenge_secret, do: System.get_env("ACME_CHALLENGE_SECRET") || "ACME-CHALLENGE-SECRET"
end
