defmodule PhxDiffWeb.BrowseLive do
  @moduledoc false
  use PhxDiffWeb, :live_view

  defmodule NotFoundError do
    defexception plug_status: 404

    def message(_) do
      "Not found"
    end
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(
        %{"app_specification" => app_spec_slug, "path" => path_segments},
        _uri,
        socket
      )
      when is_list(path_segments) do
    relative_path = Enum.join(path_segments, "/")

    with {:ok, app_spec} <- PhxDiffWeb.Params.decode_app_spec(app_spec_slug),
         {:ok, files} <- PhxDiff.list_app_files(app_spec),
         {:ok, content} <- PhxDiff.read_app_file(app_spec, relative_path) do
      {:noreply,
       socket
       |> assign(:app_spec, app_spec)
       |> assign(:files, files)
       |> assign(:selected_file, relative_path)
       |> assign(:file_content, content)
       |> assign(:page_title, "#{relative_path} — v#{app_spec.phoenix_version}")}
    else
      {:error, :invalid_version} -> raise NotFoundError
      {:error, :not_found} -> raise NotFoundError
      {:error, :binary_file} -> raise NotFoundError
      :error -> raise NotFoundError
    end
  end

  def handle_params(%{"app_specification" => app_spec_slug}, _uri, socket) do
    with {:ok, app_spec} <- PhxDiffWeb.Params.decode_app_spec(app_spec_slug),
         {:ok, files} <- PhxDiff.list_app_files(app_spec) do
      default_file = if "README.md" in files, do: "README.md", else: List.first(files)

      {:noreply,
       push_patch(socket,
         to: ~p"/browse/#{app_spec}/files/#{Path.split(default_file)}"
       )}
    else
      {:error, :invalid_version} -> raise NotFoundError
      :error -> raise NotFoundError
    end
  end
end
