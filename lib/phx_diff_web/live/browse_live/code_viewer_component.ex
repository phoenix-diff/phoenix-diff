defmodule PhxDiffWeb.BrowseLive.CodeViewerComponent do
  @moduledoc false
  use Phoenix.Component

  @extension_to_language %{
    ".ex" => "elixir",
    ".exs" => "elixir",
    ".heex" => "html",
    ".js" => "javascript",
    ".json" => "json",
    ".css" => "css",
    ".md" => "markdown"
  }

  attr :selected_file, :string, required: true
  attr :file_content, :string, required: true

  def code_viewer(assigns) do
    assigns = assign(assigns, :language_class, language_class(assigns.selected_file))

    ~H"""
    <div class="flex-1 min-w-0">
      <div class="bg-base-300 px-4 py-2 rounded-t text-sm font-medium text-base-content flex items-center gap-2">
        <svg
          xmlns="http://www.w3.org/2000/svg"
          class="h-4 w-4 shrink-0 text-base-content/60"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
          stroke-width="2"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
          />
        </svg>
        {@selected_file}
      </div>
      <div class="border border-base-300 rounded-b overflow-x-auto">
        <pre class="p-4 text-sm"><code
            id={"code-viewer-#{@selected_file}"}
            class={@language_class}
            phx-hook="CodeHighlight"
            phx-update="ignore"
          >{@file_content}</code></pre>
      </div>
    </div>
    """
  end

  attr :selected_file, :string, required: true

  def binary_file_notice(assigns) do
    ~H"""
    <div class="flex-1 min-w-0">
      <div class="bg-base-300 px-4 py-2 rounded-t text-sm font-medium text-base-content flex items-center gap-2">
        <svg
          xmlns="http://www.w3.org/2000/svg"
          class="h-4 w-4 shrink-0 text-base-content/60"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
          stroke-width="2"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
          />
        </svg>
        {@selected_file}
      </div>
      <div class="border border-base-300 rounded-b p-8 text-center text-base-content/50">
        Binary file not displayed
      </div>
    </div>
    """
  end

  defp language_class(file_path) do
    ext = Path.extname(file_path)

    case Map.get(@extension_to_language, ext) do
      nil -> "language-plaintext"
      lang -> "language-#{lang}"
    end
  end
end
