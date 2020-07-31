defmodule PhxDiffWeb.PageLive do
  @moduledoc false
  use PhxDiffWeb, :live_view

  alias Ecto.Changeset
  alias PhxDiff.Diffs
  alias PhxDiffWeb.PageLive.DiffSelection

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:no_changes?, false)
     |> assign(:all_versions, Diffs.all_versions())
     |> assign(:diff_selection, %DiffSelection{})}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    case validate_form(socket.assigns.diff_selection, params) do
      {:ok, diff_selection} ->
        %DiffSelection{source: source, target: target} = diff_selection

        {:ok, diff} =
          Diffs.get_diff(
            Diffs.fetch_default_app_specification!(source),
            Diffs.fetch_default_app_specification!(target)
          )

        {:noreply,
         socket
         |> assign(:diff_selection, diff_selection)
         |> assign(:changeset, DiffSelection.changeset(diff_selection))
         |> assign(:page_title, "v#{source} to v#{target}")
         |> assign(:no_changes?, diff == "")
         |> assign(:diff, diff)
         |> assign(:source_version, source)
         |> assign(:target_version, target)}

      {:error, _changeset} ->
        {:noreply,
         push_patch(socket,
           to:
             Routes.page_path(socket, :index,
               source: Diffs.previous_release_version(),
               target: Diffs.latest_version()
             )
         )}
    end
  end

  @impl true
  def handle_event("diff-changed", %{"diff_selection" => params}, socket) do
    case validate_form(socket.assigns.diff_selection, params) do
      {:ok, %{source: source, target: target}} ->
        {:noreply,
         push_patch(socket,
           to:
             Routes.page_path(socket, :index,
               source: source,
               target: target
             )
         )}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp validate_form(%DiffSelection{} = diff_selection, params) do
    diff_selection
    |> DiffSelection.changeset(params)
    |> Changeset.apply_action(:lookup)
  end
end
