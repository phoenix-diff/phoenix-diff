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
          <%= @patch.display_filename %>
        </.link>
      </div>
      <div class="flex-none text-sm">
        <span class="text-green-500 border-green-300 border px-0.5 rounded-l">
          +<%= @patch.summary.additions %>
        </span>
        <span class="text-red-500 border-red-300 border px-0.5 rounded-r">
          -<%= @patch.summary.deletions %>
        </span>
      </div>
    </li>
    """
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
end
