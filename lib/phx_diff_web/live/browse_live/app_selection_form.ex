defmodule PhxDiffWeb.BrowseLive.AppSelectionForm do
  @moduledoc false

  use PhxDiffWeb, :live_component

  import PhxDiffWeb.AppSelectionComponents

  alias Ecto.Changeset
  alias PhxDiff.AppSpecification
  alias PhxDiffWeb.AppSelection
  alias PhxDiffWeb.DiffSelections
  alias PhxDiffWeb.DiffSelections.DiffSelection.PhxNewArgListPresets

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form
        for={@form}
        as={:app_selection}
        id={@id}
        phx-change="form-changed"
        phx-submit="form-submit"
        class="mt-8"
        phx-target={@myself}
      >
        <div class="mb-8 inline-flex gap-4 items-end">
          <.version_select field={@form[:version]} label="Version" versions={@all_versions} />
          <.phx_new_arg_list_preset_select
            label="Arguments"
            field={@form[:variant]}
            preset_options={@variant_options}
          />
        </div>

        <div class="text-center">
          <button
            type="submit"
            role="button"
            class="border rounded-md bg-international-orange-700 font-semibold px-3 py-2 text-white shadow-sm hover:bg-international-orange-400 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-international-orange-500"
          >
            Browse
          </button>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    %{app_spec: %AppSpecification{} = app_spec} = assigns

    app_selection = AppSelection.new(app_spec)

    form =
      app_selection
      |> AppSelection.changeset(%{})
      |> to_form()

    socket =
      socket
      |> assign(assigns)
      |> assign(:app_selection, app_selection)
      |> assign(:form, form)
      |> assign(:variant_options, variant_options_for_version(app_spec.phoenix_version))
      |> assign_new(:all_versions, fn -> PhxDiff.all_versions() |> Enum.map(&to_string/1) end)

    {:ok, socket}
  end

  @impl true
  def handle_event("form-changed", %{"app_selection" => params}, socket) do
    changeset = AppSelection.changeset(socket.assigns.app_selection, params)

    variant_options =
      changeset
      |> Changeset.get_field(:version)
      |> variant_options_for_version()

    {:noreply,
     socket
     |> assign(:form, to_form(changeset))
     |> assign(:variant_options, variant_options)}
  end

  @impl true
  def handle_event("form-submit", %{"app_selection" => params}, socket) do
    changeset = AppSelection.changeset(socket.assigns.app_selection, params)

    case Changeset.apply_action(changeset, :select) do
      {:ok, app_selection} ->
        app_spec = DiffSelections.build_app_spec(app_selection.version, app_selection.variant)
        {:noreply, push_patch(socket, to: ~p"/browse/#{app_spec}")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp variant_options_for_version(version) do
    version
    |> PhxNewArgListPresets.list_known_presets_for_version()
    |> Enum.sort_by(fn
      %{id: :default} -> {0, :default}
      %{id: id} -> {1, id}
    end)
    |> Enum.map(fn preset ->
      {arguments_string(preset.arg_list) || "(Default)", preset.id}
    end)
  end

  defp arguments_string([]), do: nil

  defp arguments_string(args) when is_list(args) do
    Enum.join(args, " ")
  end
end
