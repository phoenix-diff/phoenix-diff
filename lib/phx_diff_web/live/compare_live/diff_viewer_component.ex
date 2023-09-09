defmodule PhxDiffWeb.CompareLive.DiffViewerComponent do
  @moduledoc false
  use PhxDiffWeb, :live_component

  alias Ecto.Changeset
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

        <.file_list parsed_diff={@parsed_diff} current_path={@current_path} />

        <div
          id="diff-results-container"
          class="diff-results-container hidden group-[.phx-diff-loaded-diff]:block"
          phx-hook="DiffViewerComponent"
          data-view-type={@view_type}
          data-diff={@diff}
        >
        </div>
      </.form>
      <div :if={@no_changes?} %><%= render_slot(@no_changes) %></div>
    </div>
    """
  end

  attr :parsed_diff, ParsedDiff, required: true
  attr :current_path, :string, required: true

  def file_list(assigns) do
    ~H"""
    <div class="mb-3">
      <div class="font-semibold">
        Files changed (<%= @parsed_diff.files_changed_count %>)
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
        <li :for={patch <- @parsed_diff.patches} class="px-2 py-2 flex space-x-2">
          <div class="flex-none">
            <.patch_status_icon status={patch.status} />
          </div>
          <div class="flex-1 truncate">
            <.link
              href={"#{@current_path}##{patch.html_anchor}"}
              class="text-sm text-sky-500 hover:text-sky-700"
            >
              <%= patch.display_filename %>
            </.link>
          </div>
          <div class="flex-none text-sm">
            <span class="text-green-500 border-green-300 border px-0.5 rounded-l">
              +<%= patch.summary.additions %>
            </span>
            <span class="text-red-500 border-red-300 border px-0.5 rounded-r">
              -<%= patch.summary.deletions %>
            </span>
          </div>
        </li>
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

  attr :status, :atom, required: true

  defp patch_status_icon(%{status: :added} = assigns) do
    ~H"""
    <svg
      class="stroke-[.1] stroke-green-600 fill-green-600 inline"
      aria-hidden="true"
      height="16"
      version="1.1"
      viewBox="0 0 14 16"
      width="14"
    >
      <title>Added</title>
      <path d="M13 1H1C0.45 1 0 1.45 0 2v12c0 0.55 0.45 1 1 1h12c0.55 0 1-0.45 1-1V2c0-0.55-0.45-1-1-1z m0 13H1V2h12v12zM6 9H3V7h3V4h2v3h3v2H8v3H6V9z">
      </path>
    </svg>
    """
  end

  defp patch_status_icon(%{status: :removed} = assigns) do
    ~H"""
    <svg
      class="stroke-[.1] stroke-red-600 fill-red-600 inline"
      aria-hidden="true"
      height="16"
      version="1.1"
      viewBox="0 0 14 16"
      width="14"
    >
      <title>Removed</title>
      <path d="M13 1H1C0.45 1 0 1.45 0 2v12c0 0.55 0.45 1 1 1h12c0.55 0 1-0.45 1-1V2c0-0.55-0.45-1-1-1z m0 13H1V2h12v12zM11 9H3V7h8v2z">
      </path>
    </svg>
    """
  end

  defp patch_status_icon(%{status: :renamed} = assigns) do
    ~H"""
    <svg
      class="stroke-[.1] stroke-blue-600 fill-blue-600 inline"
      aria-hidden="true"
      height="16"
      version="1.1"
      viewBox="0 0 14 16"
      width="14"
    >
      <title>Renamed</title>
      <path d="M6 9H3V7h3V4l5 4-5 4V9z m8-7v12c0 0.55-0.45 1-1 1H1c-0.55 0-1-0.45-1-1V2c0-0.55 0.45-1 1-1h12c0.55 0 1 0.45 1 1z m-1 0H1v12h12V2z">
      </path>
    </svg>
    """
  end

  defp patch_status_icon(%{status: _} = assigns) do
    ~H"""
    <svg
      class="stroke-[.1] stroke-yellow-600 fill-yellow-600 inline"
      aria-hidden="true"
      height="16"
      version="1.1"
      viewBox="0 0 14 16"
      width="14"
    >
      <title>Changed</title>
      <path d="M13 1H1C0.45 1 0 1.45 0 2v12c0 0.55 0.45 1 1 1h12c0.55 0 1-0.45 1-1V2c0-0.55-0.45-1-1-1z m0 13H1V2h12v12zM4 8c0-1.66 1.34-3 3-3s3 1.34 3 3-1.34 3-3 3-3-1.34-3-3z">
      </path>
    </svg>
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
