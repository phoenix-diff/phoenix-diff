defmodule PhxDiffWeb.DiffController do
  use PhxDiffWeb, :controller

  alias PhxDiff.Diffs

  def index(conn, %{"source" => source, "target" => target}) do
    case Diffs.get_diff(source, target) do
      {:ok, diff} ->
        conn
        |> text(diff)

      _ ->
        conn
        |> put_status(:unprocessable_entity)
        |> text("Invalid versions")
    end
  end
end
