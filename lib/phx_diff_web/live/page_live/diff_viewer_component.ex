defmodule PhxDiffWeb.PageLive.DiffViewerComponent do
  @moduledoc false
  use PhxDiffWeb, :live_component

  alias PhxDiffWeb.PageLive.DiffSelection
  alias PhxDiffWeb.PageLive.DiffViewerComponent.Renderers

  @impl true
  def update(assigns, socket) do
    socket =
      assigns
      |> Enum.flat_map(fn
        {:diff_selection, diff_selection} ->
          [diff_selection: diff_selection]

        {:diff, ""} ->
          [no_changes?: true]

        {:diff, diff} ->
          {:ok, parsed_diff} = GitDiff.parse_patch(diff)
          [no_changes?: false, diff: diff, parsed_diff: parsed_diff]

        {_, _} ->
          []
      end)
      |> Map.new()
      |> then(&assign(socket, &1))

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <%= if @no_changes? do %>
        <.no_changes_message diff_selection={@diff_selection} />
      <% else %>
        <.line_by_line_diff parsed_diff={@parsed_diff} diff_selection={@diff_selection} />
      <% end %>
    </div>
    """
  end

  defp no_changes_message(assigns) do
    ~H"""
    <div class="text-brand text-center text-xl mt-8">
      There are no changes between version <%= @diff_selection.source %> and <%= @diff_selection.target %>.
    </div>
    """
  end

  defp line_by_line_diff(assigns) do
    ~H"""
    <h1>Line by line</h1>
    <.file_list parsed_diff={@parsed_diff} diff_selection={@diff_selection} />

    <.patch :for={patch <- @parsed_diff} patch={patch} />
    """
  end

  defp patch(assigns) do
    ~H"""
    <div id={patch_id(@patch)} class="patch border-gray-200 border-2">
      <div class="header bg-gray-100 sticky top-0 p-2 flex items-center gap-1">
        <.icon name="hero-document-text" class="w-4 h-4" />
        <span class="truncate"><%= file_path(@patch) %></span>
        <.patch_status_badge status={patch_status(@patch)} />
      </div>
      <table class="w-full table-fixed font-mono">
        <colgroup>
          <col width="40" />
          <col width="40" />
          <col />
        </colgroup>

        <%= for chunk <- @patch.chunks do %>
          <tr :for={line <- chunk.lines} class={line_css_classes(line)}>
            <td class="select-none"><%= line.from_line_number %></td>
            <td class="select-none"><%= line.to_line_number %></td>
            <td class=""><.line_text line={line} /></td>
          </tr>
        <% end %>
      </table>
    </div>
    """
  end

  defp line_css_classes(%GitDiff.Line{type: :context}), do: "bg-gray-100"
  defp line_css_classes(%GitDiff.Line{type: :add}), do: "bg-green-100"
  defp line_css_classes(%GitDiff.Line{type: :remove}), do: "bg-red-100"
  defp line_css_classes(%GitDiff.Line{}), do: ""

  defp patch_status_badge(%{status: :added} = assigns) do
    ~H"""
    <span class="text-green-600 flex-none border-green-600 uppercase border-[1px] text-xs px-1">
      added
    </span>
    """
  end

  defp patch_status_badge(%{status: :removed} = assigns) do
    ~H"""
    <span class="text-red-600 flex-none border-red-600 uppercase border-[1px] text-xs px-1">
      Removed
    </span>
    """
  end

  defp patch_status_badge(%{status: :renamed} = assigns) do
    ~H"""
    <span class="text-blue-600 flex-none border-blue-600 uppercase border-[1px] text-xs px-1">
      renamed
    </span>
    """
  end

  defp patch_status_badge(assigns) do
    ~H"""
    <span class="text-yellow-600 flex-none border-yellow-600 uppercase border-[1px] text-xs px-1">
      changed
    </span>
    """
  end

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

  defp file_list(assigns) do
    ~H"""
    <div class="file-list">
      <div class="font-semibold">
        <span>Files changed (<%= length(@parsed_diff) %>)</span>
      </div>
      <ul class="divide-y divide-gray-200">
        <li :for={patch <- @parsed_diff} class="file block px-4 py-2 truncate">
          <.patch_status_icon status={patch_status(patch)} />
          <.link
            class="text-sm text-sky-500 hover:text-sky-700"
            patch={~p"/?#{to_params(@diff_selection)}" <> "##{patch_id(patch)}"}
          >
            <%= file_path(patch) %>
          </.link>
        </li>
      </ul>
    </div>
    """
  end

  defp raw_diff(assigns) do
    ~H"""
    <pre>
    <%= @diff %>
    </pre>
    """
  end

  defp file_path(%{to: to, from: from}) do
    Renderers.filename_diff(from, to)
  end

  defp patch_status(%GitDiff.Patch{headers: %{"new file mode" => _}}), do: :added
  defp patch_status(%GitDiff.Patch{headers: %{"deleted file mode" => _}}), do: :removed
  defp patch_status(%GitDiff.Patch{headers: %{"rename from" => _}}), do: :renamed
  defp patch_status(%GitDiff.Patch{}), do: :changed

  defp line_text(%{line: %GitDiff.Line{text: "+" <> text}} = assigns) do
    assigns = assign(assigns, :text, text)
    ~H"""
    <span class="select-none">+ </span><span class="[overflow-wrap:anywhere] whitespace-pre-wrap"><%= @text %></span>
    """
  end

  defp line_text(%{line: %GitDiff.Line{text: "-" <> text}} = assigns) do
    assigns = assign(assigns, :text, text)
    ~H"""
    <span class="select-none">- </span><span class="[overflow-wrap:anywhere] whitespace-pre-wrap"><%= @text %></span>
    """
  end

  defp line_text(%{line: %GitDiff.Line{text: " " <> text}} = assigns) do
    assigns = assign(assigns, :text, text)
    ~H"""
    <span class="select-none" >&nbsp;&nbsp;</span><span class="[overflow-wrap:anywhere] whitespace-pre-wrap"><%= @text %></span>
    """
  end

  defp line_text(%{line: %GitDiff.Line{text: text}} = assigns) do
    assigns = assign(assigns, :text, text)
    ~H"""
    <span class="select-none" >&nbsp;&nbsp;</span><span class="[overflow-wrap:anywhere] whitespace-pre-wrap"><%= @text %></span>
    """
  end

  defp patch_id(%GitDiff.Patch{from: from, to: to}) do
    {from, to}
    |> :erlang.phash2()
    |> to_string()
  end

  defp to_params(%DiffSelection{} = diff_selection) do
    Map.take(diff_selection, [:source, :source_variant, :target, :target_variant])
  end

  # @impl true
  # def handle_event("options-changed", %{"form" => form_params}, socket) do
  #   %{view_type: view_type} =
  #     socket.assigns.view_type
  #     |> changeset(form_params)
  #     |> Changeset.apply_action!(:update)

  #   {:noreply,
  #    socket
  #    |> assign(:changeset, changeset(view_type))
  #    |> assign(:view_type, view_type)}
  # end

  # defp changeset(current_view_type, params \\ %{}) do
  #   {%{view_type: current_view_type}, %{view_type: :string}}
  #   |> Changeset.cast(params, [:view_type])
  #   |> Changeset.validate_required([:view_type])
  #   |> Changeset.validate_inclusion(:view_type, ["line-by-line", "side-by-side"])
  # end
end
