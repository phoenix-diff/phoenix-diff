defmodule PhxDiffWeb.PageLive do
  @moduledoc false
  use PhxDiffWeb, :live_view

  alias Ecto.Changeset
  alias PhxDiff.AppSpecification
  alias PhxDiff.ComparisonError
  alias PhxDiffWeb.PageLive.DiffSelection

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:no_changes?, false)
     |> assign(:all_versions, PhxDiff.all_versions() |> Enum.map(&to_string/1))
     |> assign(:diff_selection, %DiffSelection{})}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    case fetch_diff(socket.assigns.diff_selection, params) do
      {:ok, {diff_selection, source_app_spec, target_app_spec, diff}} ->
        {:noreply,
         socket
         |> assign(:diff_selection, diff_selection)
         |> assign(:changeset, DiffSelection.changeset(diff_selection))
         |> assign(:page_title, page_title(source_app_spec, target_app_spec))
         |> assign(:no_changes?, diff == "")
         |> assign(:diff, diff)
         |> assign(:source_version, source_app_spec.phoenix_version)
         |> assign(:source_arguments, arguments_string(source_app_spec))
         |> assign(:target_version, target_app_spec.phoenix_version)
         |> assign(:target_arguments, arguments_string(target_app_spec))}

      {:error, _changeset} ->
        {:noreply,
         push_patch(socket,
           to:
             ~p"/?source=#{PhxDiff.previous_release_version()}&target=#{PhxDiff.latest_version()}"
         )}
    end
  end

  @impl true
  def handle_event("diff-changed", %{"diff_selection" => params}, socket) do
    changeset = DiffSelection.changeset(socket.assigns.diff_selection, params)

    case Changeset.apply_action(changeset, :lookup) do
      {:ok, %{source: source, target: target}} ->
        {:noreply, push_patch(socket, to: ~p"/?source=#{source}&target=#{target}")}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  @spec fetch_diff(DiffSelection.t(), map) ::
          {:ok, {DiffSelection.t(), AppSpecification.t(), AppSpecification.t(), PhxDiff.diff()}}
          | {:error, Changeset.t()}
  defp fetch_diff(%DiffSelection{} = diff_selection, params) do
    changeset = DiffSelection.changeset(diff_selection, params)

    with {:ok, diff_selection} <- Changeset.apply_action(changeset, :lookup) do
      %DiffSelection{source: source, target: target} = diff_selection
      source_app_spec = PhxDiff.default_app_specification(source)
      target_app_spec = PhxDiff.default_app_specification(target)

      case PhxDiff.fetch_diff(source_app_spec, target_app_spec) do
        {:ok, diff} ->
          {:ok, {diff_selection, source_app_spec, target_app_spec, diff}}

        {:error, %ComparisonError{} = error} ->
          changeset =
            Enum.reduce(error.errors, changeset, fn {field, :unknown_version}, changeset ->
              Changeset.add_error(changeset, field, "is unknown")
            end)

          {:error, changeset}
      end
    end
  end

  defp page_title(%AppSpecification{} = source, %AppSpecification{} = target) do
    "v#{source.phoenix_version} to v#{target.phoenix_version}"
  end

  defp arguments_string(%AppSpecification{phx_new_arguments: []}), do: nil

  defp arguments_string(%AppSpecification{phx_new_arguments: args}) do
    Enum.join(args, " ")
  end
end
