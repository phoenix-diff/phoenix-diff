defmodule PhxDiffWeb.PageLive.DiffViewerComponent do
  @moduledoc false
  use PhxDiffWeb, :live_component

  alias Ecto.Changeset

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form
        :let={f}
        for={@changeset}
        as={:form}
        id={"diff-viewer-form-#{@id}"}
        phx-change="options-changed"
        phx-target={@myself}
      >
        <div id="diff-view-toggles" class="text-center mb-4">
          <div class="font-bold inline">Display mode:</div>

          <.button_group_toggle field={{f, :view_type}} class="m-2">
            <:option value="line-by-line">Line by line</:option>
            <:option value="side-by-side">Side by side</:option>
          </.button_group_toggle>
        </div>

        <div
          id="diff-results-container"
          class="diff-results-container hidden group-[.phx-diff-loaded-diff]:block"
          phx-hook="DiffViewerComponent"
          data-view-type={@view_type}
          data-diff={@diff}
        >
        </div>
      </.form>
    </div>
    """
  end

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
