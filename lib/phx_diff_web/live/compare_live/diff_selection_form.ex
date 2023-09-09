defmodule PhxDiffWeb.CompareLive.DiffSelectionForm do
  @moduledoc false

  use PhxDiffWeb, :live_component

  import PhxDiffWeb.CompareLive.DiffSelectionComponents

  alias PhxDiff.AppSpecification
  alias PhxDiffWeb.CompareLive.DiffSelection
  alias PhxDiffWeb.CompareLive.DiffSelection.PhxNewArgListPresets

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form
        for={@form}
        as={:diff_selection}
        id={@id}
        phx-change="diff-changed"
        phx-hook="DiffSelectorComponent"
        class="mt-8 mb-11 sm:my-12 sm:inline-grid gap-4 grid-cols-2 grid-rows-1"
        phx-target={@myself}
      >
        <div id="source-selector" class="mb-3 sm:mb-0">
          <div>
            <h4 class="uppercase underline text-sm sm:mb-2">Source</h4>
          </div>
          <.version_select field={@form[:source]} label="Source" versions={@all_versions} />
          <.phx_new_arg_list_preset_select
            field={@form[:source_variant]}
            preset_options={@source_variants}
          />
        </div>

        <div id="target-selector" class="mb-3 sm:mb-0">
          <div>
            <h4 class="uppercase underline text-sm sm:mb-2">Target</h4>
          </div>
          <.version_select field={@form[:target]} label="Target" versions={@all_versions} />
          <.phx_new_arg_list_preset_select
            field={@form[:target_variant]}
            preset_options={@target_variants}
          />
        </div>
      </.form>
    </div>
    """
  end

  @impl true
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
        form =
          socket.assigns.source_app_spec
          |> DiffSelection.new(socket.assigns.target_app_spec)
          |> DiffSelection.changeset()
          |> to_form()

        assign(socket, :form, form)
      end)

    {:ok, socket}
  end

  @impl true
  def handle_event("diff-changed", %{"diff_selection" => params}, socket) do
    {:noreply, push_patch(socket, to: ~p"/?#{params}")}
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
