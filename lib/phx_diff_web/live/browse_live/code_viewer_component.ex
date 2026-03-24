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
      <div class="bg-zinc-100 px-4 py-2 rounded-t text-sm font-medium text-zinc-700">
        {@selected_file}
      </div>
      <div class="border border-zinc-200 rounded-b overflow-x-auto">
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
      <div class="bg-zinc-100 px-4 py-2 rounded-t text-sm font-medium text-zinc-700">
        {@selected_file}
      </div>
      <div class="border border-zinc-200 rounded-b p-8 text-center text-zinc-500">
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
