defmodule PhxDiffWeb.PageLive do
  @moduledoc false
  use PhxDiffWeb, :live_view

  alias Ecto.Changeset
  alias PhxDiff.AppSpecification
  alias PhxDiff.ComparisonError
  alias PhxDiffWeb.PageLive.DiffSelection
  alias PhxDiffWeb.PageLive.DiffSelection.PhxNewArgListPresets

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
         |> assign(:current_path, ~p"/?#{to_params(diff_selection)}")
         |> assign(:changeset, DiffSelection.changeset(diff_selection))
         |> assign(:page_title, page_title(source_app_spec, target_app_spec))
         |> assign(:no_changes?, diff == "")
         |> assign(:diff, diff)
         |> assign(:source_version, source_app_spec.phoenix_version)
         |> assign(:target_version, target_app_spec.phoenix_version)}

      {:error, changeset} ->
        diff_selection = find_valid_diff_selection(changeset)

        {:noreply,
         push_patch(socket,
           to: ~p"/?#{to_params(diff_selection)}"
         )}
    end
  end

  @impl true
  def handle_event("diff-changed", %{"diff_selection" => params}, socket) do
    changeset = DiffSelection.changeset(socket.assigns.diff_selection, params)

    diff_selection =
      case Changeset.apply_action(changeset, :lookup) do
        {:ok, diff_selection} -> diff_selection
        {:error, changeset} -> find_valid_diff_selection(changeset)
      end

    {:noreply, push_patch(socket, to: ~p"/?#{to_params(diff_selection)}")}
  end

  @spec fetch_diff(DiffSelection.t(), map) ::
          {:ok, {DiffSelection.t(), AppSpecification.t(), AppSpecification.t(), PhxDiff.diff()}}
          | {:error, Changeset.t()}
  defp fetch_diff(%DiffSelection{} = diff_selection, params) do
    changeset = DiffSelection.changeset(diff_selection, params)

    with {:ok, diff_selection} <- Changeset.apply_action(changeset, :lookup) do
      source_app_spec = build_app_spec(diff_selection.source, diff_selection.source_variant)
      target_app_spec = build_app_spec(diff_selection.target, diff_selection.target_variant)

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

  defp build_app_spec(version, nil), do: PhxDiff.default_app_specification(version)

  defp build_app_spec(version, variant_id) do
    {:ok, preset} = PhxNewArgListPresets.fetch(variant_id)
    AppSpecification.new(version, preset.arg_list)
  end

  defp find_valid_diff_selection(changeset) do
    diff_selection = Changeset.apply_changes(changeset)
    error_fields = Keyword.keys(changeset.errors)

    diff_selection =
      if :source in error_fields do
        %{diff_selection | source: PhxDiff.previous_release_version()}
      else
        diff_selection
      end

    diff_selection =
      if :target in error_fields do
        %{diff_selection | target: PhxDiff.latest_version()}
      else
        diff_selection
      end

    diff_selection =
      if :source_variant in error_fields do
        %{
          diff_selection
          | source_variant: PhxNewArgListPresets.get_default_for_version(diff_selection.source).id
        }
      else
        diff_selection
      end

    diff_selection =
      if :target_variant in error_fields do
        %{
          diff_selection
          | target_variant: PhxNewArgListPresets.get_default_for_version(diff_selection.target).id
        }
      else
        diff_selection
      end

    diff_selection
  end

  defp to_params(%DiffSelection{} = diff_selection) do
    Map.take(diff_selection, [:source, :source_variant, :target, :target_variant])
  end
end
