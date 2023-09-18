defmodule PhxDiffWeb.CompareLive do
  @moduledoc false
  use PhxDiffWeb, :live_view

  alias Ecto.Changeset
  alias Phoenix.LiveView.Socket
  alias PhxDiff.AppSpecification
  alias PhxDiff.ComparisonError
  alias PhxDiffWeb.DiffSelections
  alias PhxDiffWeb.DiffSelections.DiffSelection
  alias PhxDiffWeb.DiffSelections.DiffSelection.PhxNewArgListPresets

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:no_changes?, false)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    params =
      Enum.reduce(params, %{}, fn
        {"source", version}, acc ->
          put_in(acc, [Access.key("source", %{}), "version"], version)

        {"source_variant", variant}, acc ->
          put_in(acc, [Access.key("source", %{}), "variant"], variant)

        {"target", version}, acc ->
          put_in(acc, [Access.key("target", %{}), "version"], version)

        {"target_variant", variant}, acc ->
          put_in(acc, [Access.key("target", %{}), "variant"], variant)

        _, acc ->
          acc
      end)

    with {:ok, source_app_spec, target_app_spec} <- fetch_source_and_target_app_specs(params),
         socket = assign_app_specs(socket, source_app_spec, target_app_spec),
         {:ok, socket} <-
           fetch_and_assign_diff_when_connected(socket, source_app_spec, target_app_spec) do
      {:noreply, socket}
    else
      {:error, changeset} ->
        diff_selection = DiffSelections.find_valid_diff_selection(changeset)

        {:noreply,
         push_patch(socket,
           to: ~p"/?#{to_params(diff_selection)}"
         )}
    end
  end

  @spec fetch_source_and_target_app_specs(map) ::
          {:ok, AppSpecification.t(), AppSpecification.t()} | {:error, Changeset.t()}
  defp fetch_source_and_target_app_specs(params) do
    changeset = DiffSelection.changeset(%DiffSelection{}, params)

    with {:ok, diff_selection} <- Changeset.apply_action(changeset, :lookup) do
      source_app_spec =
        build_app_spec(diff_selection.source.version, diff_selection.source.variant)

      target_app_spec =
        build_app_spec(diff_selection.target.version, diff_selection.target.variant)

      {:ok, source_app_spec, target_app_spec}
    end
  end

  @spec assign_app_specs(Socket.t(), AppSpecification.t(), AppSpecification.t()) :: Socket.t()
  def assign_app_specs(socket, source_app_spec, target_app_spec) do
    socket
    |> assign(:source_app_spec, source_app_spec)
    |> assign(:target_app_spec, target_app_spec)
    |> assign(:page_title, page_title(source_app_spec, target_app_spec))
    |> assign(:source_version, source_app_spec.phoenix_version)
    |> assign(:target_version, target_app_spec.phoenix_version)
    |> assign(:current_path, ~p"/?#{to_params(source_app_spec, target_app_spec)}")
  end

  @spec fetch_and_assign_diff_when_connected(
          Socket.t(),
          AppSpecification.t(),
          AppSpecification.t()
        ) :: {:ok, Socket.t()} | {:error, Changeset.t()}
  defp fetch_and_assign_diff_when_connected(socket, source_app_spec, target_app_spec) do
    with :connected <- halt_unless_connected(socket),
         {:ok, diff} <- fetch_diff(source_app_spec, target_app_spec) do
      {:ok,
       socket
       |> assign(:diff, diff)
       |> assign(:no_changes?, diff == "")}
    end
  end

  defp halt_unless_connected(socket) do
    if connected?(socket) do
      :connected
    else
      {:ok, socket}
    end
  end

  @spec fetch_diff(AppSpecification.t(), AppSpecification.t()) ::
          {:ok, String.t()} | {:error, Changeset.t()}
  defp fetch_diff(source_app_spec, target_app_spec) do
    case PhxDiff.fetch_diff(source_app_spec, target_app_spec) do
      {:ok, diff} ->
        {:ok, diff}

      {:error, %ComparisonError{} = error} ->
        changeset =
          DiffSelection.new(source_app_spec, target_app_spec)
          |> DiffSelection.changeset()

        changeset =
          Enum.reduce(error.errors, changeset, fn {field, :unknown_version}, changeset ->
            Changeset.add_error(changeset, field, "is unknown")
          end)

        {:error, changeset}
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

  defp to_params(%AppSpecification{} = source, %AppSpecification{} = target) do
    source
    |> DiffSelection.new(target)
    |> to_params()
  end

  defp to_params(%DiffSelection{} = diff_selection) do
    [
      source: get_in(diff_selection, [Access.key!(:source), Access.key(:version)]) |> to_string(),
      source_variant:
        get_in(diff_selection, [Access.key!(:source), Access.key(:variant)]) |> to_string(),
      target: get_in(diff_selection, [Access.key!(:target), Access.key(:version)]) |> to_string(),
      target_variant:
        get_in(diff_selection, [Access.key!(:target), Access.key(:variant)]) |> to_string()
    ]
  end
end
