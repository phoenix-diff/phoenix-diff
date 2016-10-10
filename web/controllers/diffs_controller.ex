defmodule PhoenixDiff.DiffsController do
  use PhoenixDiff.Web, :controller

  alias PhoenixDiff.Diff

  def show(conn, %{"from" => from, "to" => to}), do: conn |> text(Diff.get(from, to))
end
