defmodule PhxDiffWeb.PageLive.DiffViewerComponent do
  @moduledoc false
  use PhxDiffWeb, :live_component

  alias Ecto.Changeset

  @impl true
  def mount(socket) do
    view_type = "line-by-line"

    {:ok,
     socket
     |> assign(:changeset, changeset(view_type))
     |> assign(:view_type, view_type)}
  end

  @impl true
  def handle_event("options-changed", %{"form" => form_params}, socket) do
    %{view_type: view_type} =
      socket.assigns.view_type
      |> changeset(form_params)
      |> Changeset.apply_action!(:update)

    {:noreply,
     socket
     |> assign(:changeset, changeset(view_type))
     |> assign(:view_type, view_type)}
  end

  defp changeset(current_view_type, params \\ %{}) do
    {%{view_type: current_view_type}, %{view_type: :string}}
    |> Changeset.cast(params, [:view_type])
    |> Changeset.validate_required([:view_type])
    |> Changeset.validate_inclusion(:view_type, ["line-by-line", "side-by-side"])
  end
end
