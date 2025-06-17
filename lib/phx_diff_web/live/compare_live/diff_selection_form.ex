defmodule PhxDiffWeb.CompareLive.DiffSelectionForm do
  @moduledoc false

  use PhxDiffWeb, :live_component

  import PhxDiffWeb.CompareLive.DiffSelectionComponents

  alias Ecto.Changeset
  alias PhxDiff.AppSpecification
  alias PhxDiffWeb.AppSelection
  alias PhxDiffWeb.DiffSelections
  alias PhxDiffWeb.DiffSelections.DiffSelection
  alias PhxDiffWeb.DiffSelections.DiffSelection.PhxNewArgListPresets

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form
        for={@form}
        as={:diff_selection}
        id={@id}
        phx-change="form-changed"
        phx-submit="form-submit"
        phx-hook="DiffSelectorComponent"
        class="mt-8"
        phx-target={@myself}
      >
        <div class="mb-8 sm:inline-grid gap-4 grid-cols-2 grid-rows-1">
          <fieldset id="source-selector" class="mb-3 sm:mb-0">
            <legend class="uppercase underline text-sm sm:mb-2 w-full text-neutral-content">
              Source
            </legend>
            <.inputs_for :let={source_form} field={@form[:source]}>
              <.version_select field={source_form[:version]} label="Version" versions={@all_versions} />
              <.phx_new_arg_list_preset_select
                label="Arguments"
                field={source_form[:variant]}
                preset_options={@source_variants}
              />
            </.inputs_for>
          </fieldset>

          <fieldset id="target-selector" class="mb-3 sm:mb-0">
            <legend class="uppercase underline text-sm sm:mb-2 w-full text-neutral-content">
              Target
            </legend>
            <.inputs_for :let={target_form} field={@form[:target]}>
              <.version_select field={target_form[:version]} label="Version" versions={@all_versions} />
              <.phx_new_arg_list_preset_select
                label="Arguments"
                field={target_form[:variant]}
                preset_options={@target_variants}
              />
            </.inputs_for>
          </fieldset>
        </div>

        <div class="text-center">
          <button
            type="submit"
            role="button"
            class="border rounded-md bg-international-orange-700 font-semibold px-3 py-2 text-white shadow-sm hover:bg-international-orange-400 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-international-orange-500"
          >
            Generate Diff
          </button>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  @spec update(any(), any()) :: {:ok, any()}
  def update(assigns, socket) do
    socket =
      assigns
      |> Enum.reduce(socket, fn
        {:source_app_spec, %AppSpecification{} = source}, socket ->
          socket
          |> assign(:source_app_spec, source)
          |> assign(:source_variants, variant_options_for_version(source.phoenix_version))

        {:target_app_spec, %AppSpecification{} = target}, socket ->
          socket
          |> assign(:target_app_spec, target)
          |> assign(:target_variants, variant_options_for_version(target.phoenix_version))

        {k, v}, socket ->
          assign(socket, k, v)
      end)
      |> assign_new(:all_versions, fn -> PhxDiff.all_versions() |> Enum.map(&to_string/1) end)
      |> then(fn socket ->
        diff_selection = %DiffSelection{
          source: AppSelection.new(socket.assigns.source_app_spec),
          target: AppSelection.new(socket.assigns.target_app_spec)
        }

        form =
          diff_selection
          |> DiffSelection.changeset(%{})
          |> to_form()

        assign(socket, form: form, diff_selection: diff_selection)
      end)

    {:ok, socket}
  end

  @impl true
  def handle_event("form-changed", %{"diff_selection" => params}, socket) do
    changeset = DiffSelection.changeset(socket.assigns.diff_selection, params)

    socket =
      changeset
      |> Changeset.get_field(:source)
      |> Map.fetch!(:version)
      |> variant_options_for_version()
      |> then(&assign(socket, :source_variants, &1))

    socket =
      changeset
      |> Changeset.get_field(:target)
      |> Map.fetch!(:version)
      |> variant_options_for_version()
      |> then(&assign(socket, :target_variants, &1))

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("form-submit", %{"diff_selection" => params}, socket) do
    changeset = DiffSelection.changeset(socket.assigns.diff_selection, params)

    case Changeset.apply_action(changeset, :select) do
      {:ok, diff_selection} ->
        diff_specification = DiffSelections.build_diff_specification(diff_selection)
        {:noreply, push_patch(socket, to: ~p"/compare/#{diff_specification}")}

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
