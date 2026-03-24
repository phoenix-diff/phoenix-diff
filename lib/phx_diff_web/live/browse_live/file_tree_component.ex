defmodule PhxDiffWeb.BrowseLive.FileTreeComponent do
  @moduledoc false
  use PhxDiffWeb, :html

  alias Phoenix.LiveView.JS

  attr :app_spec, :any, required: true
  attr :files, :list, required: true
  attr :selected_file, :string, required: true

  def file_tree(assigns) do
    assigns = assign(assigns, :tree, build_tree(assigns.files))

    ~H"""
    <div>
      <button
        id="file-tree-toggle"
        class="sm:hidden flex items-center w-full text-left px-2 py-2 text-sm font-semibold text-zinc-300 border-b border-zinc-700"
        phx-click={toggle_file_tree()}
      >
        <span id="file-tree-toggle-chevron-right">
          <.icon name="hero-chevron-right" class="!size-4 mr-1" />
        </span>
        <span id="file-tree-toggle-chevron-down" class="hidden">
          <.icon name="hero-chevron-down" class="!size-4 mr-1" />
        </span>
        Files ({length(@files)})
      </button>
      <nav id="file-tree" class="hidden sm:!block">
        <ul class="space-y-0.5">
          <.tree_entries
            entries={@tree}
            app_spec={@app_spec}
            selected_file={@selected_file}
            prefix=""
            depth={0}
          />
        </ul>
      </nav>
    </div>
    """
  end

  attr :entries, :list, required: true
  attr :app_spec, :any, required: true
  attr :selected_file, :string, required: true
  attr :prefix, :string, required: true
  attr :depth, :integer, required: true

  defp tree_entries(assigns) do
    ~H"""
    <%= for entry <- @entries do %>
      <%= case entry do %>
        <% {dir, children} -> %>
          <% dir_path = @prefix <> dir <> "/" %>
          <% dir_id = "dir-#{@prefix <> dir}" |> String.replace(~r/[^a-zA-Z0-9-]/, "-") %>
          <% open? = String.starts_with?(@selected_file, dir_path) %>
          <li>
            <button
              class="flex items-center w-full py-1 text-sm text-zinc-400 hover:text-zinc-200 cursor-pointer"
              style={"padding-left: #{@depth * 0.75 + 0.5}rem"}
              phx-click={toggle_directory(dir_id)}
            >
              <span id={"#{dir_id}-chevron-right"} class={[open? && "hidden"]}>
                <.icon name="hero-chevron-right" class="size-3 mr-1 text-zinc-400" />
              </span>
              <span id={"#{dir_id}-chevron-down"} class={[!open? && "hidden"]}>
                <.icon name="hero-chevron-down" class="size-3 mr-1 text-zinc-400" />
              </span>
              <span id={"#{dir_id}-folder-closed"} class={[open? && "hidden"]}>
                <.icon name="hero-folder" class="size-4 mr-1 text-zinc-400" />
              </span>
              <span id={"#{dir_id}-folder-open"} class={[!open? && "hidden"]}>
                <.icon name="hero-folder-open" class="size-4 mr-1 text-zinc-400" />
              </span>
              {dir}
            </button>
            <ul id={dir_id} class={["space-y-0.5", !open? && "hidden"]}>
              <.tree_entries
                entries={children}
                app_spec={@app_spec}
                selected_file={@selected_file}
                prefix={@prefix <> dir <> "/"}
                depth={@depth + 1}
              />
            </ul>
          </li>
        <% file when is_binary(file) -> %>
          <% full_path = @prefix <> file %>
          <li>
            <.link
              patch={~p"/browse/#{@app_spec}/files/#{Path.split(full_path)}"}
              class={[
                "flex items-center py-1 text-sm rounded hover:bg-zinc-700 truncate",
                full_path == @selected_file && "bg-zinc-700 text-orange-400 font-medium"
              ]}
              style={"padding-left: #{@depth * 0.75 + 0.5}rem"}
            >
              <span class="size-3 mr-1 shrink-0"></span>
              <.icon name="hero-document" class="size-4 mr-1 shrink-0 text-zinc-400" />
              {file}
            </.link>
          </li>
      <% end %>
    <% end %>
    """
  end

  defp toggle_directory(dir_id, js \\ %JS{}) do
    js
    |> JS.toggle(to: "##{dir_id}")
    |> JS.toggle(to: "##{dir_id}-chevron-right")
    |> JS.toggle(to: "##{dir_id}-chevron-down")
    |> JS.toggle(to: "##{dir_id}-folder-closed")
    |> JS.toggle(to: "##{dir_id}-folder-open")
  end

  defp toggle_file_tree(js \\ %JS{}) do
    js
    |> JS.toggle(
      to: "#file-tree",
      in: {"transition-all transform ease-in duration-200", "opacity-0", "opacity-100"},
      out: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> JS.toggle(to: "#file-tree-toggle-chevron-right")
    |> JS.toggle(to: "#file-tree-toggle-chevron-down")
  end

  @doc false
  def build_tree(files) do
    files
    |> Enum.reduce(%{}, fn file, acc ->
      parts = Path.split(file)
      insert_path(acc, parts)
    end)
    |> tree_to_sorted_list()
  end

  defp insert_path(tree, [file]) do
    Map.update(tree, :files, [file], &[file | &1])
  end

  defp insert_path(tree, [dir | rest]) do
    subtree = Map.get(tree, dir, %{})
    Map.put(tree, dir, insert_path(subtree, rest))
  end

  defp tree_to_sorted_list(tree) do
    {files, dirs} =
      tree
      |> Enum.split_with(fn {key, _val} -> key == :files end)

    sorted_files =
      case files do
        [{:files, file_list}] -> Enum.sort(file_list)
        [] -> []
      end

    sorted_dirs =
      dirs
      |> Enum.sort_by(fn {name, _} -> name end)
      |> Enum.map(fn {name, subtree} -> {name, tree_to_sorted_list(subtree)} end)

    sorted_dirs ++ sorted_files
  end
end
