defmodule PhxDiffWeb.CompareLive.DiffViewerComponent do
  @moduledoc false
  use PhxDiffWeb, :live_component

  alias Ecto.Changeset
  alias PhxDiffWeb.CompareLive.DiffViewerComponent.FileListItem
  alias PhxDiffWeb.CompareLive.DiffViewerComponent.ParsedDiff

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form
        :let={f}
        :if={!@no_changes?}
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

        <.file_list parsed_diff={@parsed_diff} />

        <div
          id="diff-results-container"
          class="diff-results-container hidden group-[.phx-diff-loaded-diff]:block"
          phx-hook="DiffViewerComponent"
          data-view-type={@view_type}
          data-diff={@diff}
          data-target-url={@target_url}
        >
        </div>
      </.form>
      <div :if={@no_changes?} %>{render_slot(@no_changes)}</div>
    </div>
    """
  end

  attr :parsed_diff, ParsedDiff, required: true

  def file_list(assigns) do
    ~H"""
    <div class="mb-3">
      <div class="font-semibold">
        Files changed ({@parsed_diff.files_changed_count})
        <.link
          id="file-list-show-link"
          class="text-orange-500 hover:text-orange-700 text-sm"
          phx-click={show_file_list()}
        >
          show
        </.link>
        <.link
          id="file-list-hide-link"
          class="text-orange-500 hover:text-orange-700 hidden text-sm"
          phx-click={hide_file_list()}
        >
          hide
        </.link>
      </div>
      <ul id="file-list" class="file-list divide-y divide-gray-200 hidden">
        <.live_component
          :for={patch <- @parsed_diff.patches}
          id={"file-list-#{patch.display_filename_hash}"}
          module={FileListItem}
          patch={patch}
        />
      </ul>
    </div>
    """
  end

  defp show_file_list(js \\ %JS{}) do
    js
    |> JS.show(
      to: "#file-list",
      transition: {"transition-all transform ease-in duration-200", "opacity-0", "opacity-100"}
    )
    |> JS.hide(to: "#file-list-show-link")
    |> JS.show(to: "#file-list-hide-link", display: "inline")
  end

  defp hide_file_list(js \\ %JS{}) do
    js
    |> JS.hide(
      to: "#file-list",
      transition: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> JS.show(to: "#file-list-show-link", display: "inline")
    |> JS.hide(to: "#file-list-hide-link")
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
  def update(assigns, socket) do
    socket =
      Enum.reduce(assigns, socket, fn
        {:diff, ""}, socket ->
          assign(socket, %{no_changes?: true})

        {:diff, diff}, socket ->
          {:ok, parsed_diff} = ParsedDiff.parse(diff)

          assign(socket, %{diff: diff, parsed_diff: parsed_diff, no_changes?: false})

        {key, value}, socket ->
          assign(socket, key, value)
      end)

    {:ok, socket}
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
