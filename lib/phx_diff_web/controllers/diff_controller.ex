defmodule PhxDiffWeb.DiffController do
  use PhxDiffWeb, :controller

  alias PhxDiff.Diffs
  alias PhxDiff.Diffs.AppSpecification

  def index(conn, %{"source" => source, "target" => target}) do
    source_spec = AppSpecification.new(source)
    target_spec = AppSpecification.new(target)

    case Diffs.get_diff(source_spec, target_spec) do
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
