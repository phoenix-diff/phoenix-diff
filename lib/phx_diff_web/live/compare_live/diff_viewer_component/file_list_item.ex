defmodule PhxDiffWeb.CompareLive.DiffViewerComponent.FileListItem do
  @moduledoc false

  use PhxDiffWeb, :live_component

  def render(assigns) do
    ~H"""
    <li class="px-2 py-2 flex space-x-2">
      <div class="flex-none">
        <.patch_status_icon status={@patch.status} />
      </div>
      <div class="flex-1 truncate">
        <.link href={"##{@patch.html_anchor}"} class="text-sm text-sky-500 hover:text-sky-700">
          {@patch.display_filename}
        </.link>
      </div>
      <div class="flex-none text-sm">
        <span class="text-green-500 border-green-300 border px-0.5 rounded-l">
          +{@patch.summary.additions}
        </span>
        <span class="text-red-500 border-red-300 border px-0.5 rounded-r">
          -{@patch.summary.deletions}
        </span>
      </div>
    </li>
    """
  end

  attr :status, :atom, required: true

  defp patch_status_icon(%{status: :added} = assigns) do
    ~H"""
    <.icon name="fa-plus-solid" class="w-3 h-3 text-green-600" />
    <span class="sr-only">Added</span>
    """
  end

  defp patch_status_icon(%{status: :removed} = assigns) do
    ~H"""
    <.icon name="fa-plus-solid" class="w-3 h-3 text-red-600" />
    <span class="sr-only">Removed</span>
    """
  end

  defp patch_status_icon(%{status: :renamed} = assigns) do
    ~H"""
    <.icon name="fa-arrow-right-solid" class="w-3 h-3 text-blue-600" />
    <span class="sr-only">Renamed</span>
    """
  end

  defp patch_status_icon(%{status: _} = assigns) do
    ~H"""
    <.icon name="fa-plus-minus-solid" class="w-3 h-3 text-yellow-600" />
    <span class="sr-only">Changed</span>
    """
  end
end
