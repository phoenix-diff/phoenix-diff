defmodule PhxDiffWeb.BrowseLive.CodeViewerComponent do
  @moduledoc false
  use PhxDiffWeb, :html

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
  attr :app_spec, :any, required: true

  def code_viewer(assigns) do
    assigns = assign(assigns, :language_class, language_class(assigns.selected_file))

    ~H"""
    <div class="flex-1 min-w-0">
      <.file_header selected_file={@selected_file} app_spec={@app_spec} />
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
  attr :app_spec, :any, required: true

  def binary_file_notice(assigns) do
    ~H"""
    <div class="flex-1 min-w-0">
      <.file_header selected_file={@selected_file} app_spec={@app_spec} />
      <div class="border border-base-300 rounded-b p-8 text-center text-base-content/50">
        Binary file not displayed
      </div>
    </div>
    """
  end

  attr :selected_file, :string, required: true
  attr :app_spec, :any, required: true

  defp file_header(assigns) do
    assigns =
      assign(assigns, :raw_file_url, raw_file_url(assigns.app_spec, assigns.selected_file))

    ~H"""
    <div class="bg-base-300 px-4 py-2 rounded-t text-sm font-medium text-base-content flex items-center gap-2">
      <.icon name="hero-document-text" class="size-4 shrink-0 text-base-content/60" />
      <span class="flex-1 truncate">{@selected_file}</span>
      <a
        href={@raw_file_url}
        target="_blank"
        class="text-xs font-medium px-2 py-0.5 rounded border border-base-content/20 text-base-content/60 hover:text-base-content hover:border-base-content/40 hover:bg-base-content/5 transition-colors"
      >
        Raw
      </a>
    </div>
    """
  end

  defp raw_file_url(app_spec, selected_file) do
    ~p"/browse/#{app_spec}/raw/#{Path.split(selected_file)}"
  end

  defp language_class(file_path) do
    ext = Path.extname(file_path)

    case Map.get(@extension_to_language, ext) do
      nil -> "language-plaintext"
      lang -> "language-#{lang}"
    end
  end
end
