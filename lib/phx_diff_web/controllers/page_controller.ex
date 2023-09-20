defmodule PhxDiffWeb.PageController do
  use PhxDiffWeb, :controller

  alias PhxDiffWeb.DiffSelections
  alias PhxDiffWeb.DiffSelections.DiffSelection
  alias PhxDiffWeb.DiffSpecification

  def index(conn, params) do
    params =
      Enum.reduce(params, %{}, fn
        {"source", version}, acc ->
          put_in(acc, [Access.key("source", %{}), "version"], version)

        {"source_variant", variant}, acc ->
          put_in(acc, [Access.key("source", %{}), "variant"], variant)

        {"target", version}, acc ->
          put_in(acc, [Access.key("target", %{}), "version"], version)

        {"target_variant", variant}, acc ->
          put_in(acc, [Access.key("target", %{}), "variant"], variant)

        _, acc ->
          acc
      end)

    diff_specification =
      %DiffSelection{}
      |> DiffSelection.changeset(params)
      |> DiffSelections.find_valid_diff_selection()
      |> build_diff_specification()

    redirect(conn, to: ~p"/compare/#{diff_specification}")
  end

  def compare(conn, _params) do
    # Redirect to default
    diff_specification =
      %DiffSelection{}
      |> DiffSelection.changeset(%{})
      |> DiffSelections.find_valid_diff_selection()
      |> DiffSelections.build_diff_specification()

    redirect(conn, to: ~p"/compare/#{diff_specification}")
  end

  defp build_diff_specification(%DiffSelection{} = diff_selection) do
    source =
      DiffSelections.build_app_spec(diff_selection.source.version, diff_selection.source.variant)

    target =
      DiffSelections.build_app_spec(diff_selection.target.version, diff_selection.target.variant)

    DiffSpecification.new(source, target)
  end
end
