defmodule PhxDiffWeb.PageLive.DiffSelectionForm do
  @moduledoc false

  use PhxDiffWeb, :live_component

  import PhxDiffWeb.PageLive.DiffSelectionComponents

  alias PhxDiffWeb.PageLive.DiffSelection
  alias PhxDiffWeb.PageLive.DiffSelection.PhxNewArgListPresets

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form
        :let={f}
        for={@changeset}
        as={:diff_selection}
        id={@id}
        phx-change="diff-changed"
        phx-hook="DiffSelectorComponent"
        class="mt-8 mb-11 sm:my-12 sm:inline-grid gap-4 grid-cols-2 grid-rows-1"
      >
        <div id="source-selector" class="mb-3 sm:mb-0">
          <div>
            <h4 class="uppercase underline text-sm sm:mb-2">Source</h4>
          </div>
          <.version_select field={{f, :source}} label="Source" versions={@all_versions} />
          <.phx_new_arg_list_preset_select
            field={{f, :source_variant}}
            preset_options={@source_variants}
          />
        </div>

        <div id="target-selector" class="mb-3 sm:mb-0">
          <div>
            <h4 class="uppercase underline text-sm sm:mb-2">Target</h4>
          </div>
          <.version_select field={{f, :target}} label="Target" versions={@all_versions} />
          <.phx_new_arg_list_preset_select
            field={{f, :target_variant}}
            preset_options={@target_variants}
          />
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def update(%{diff_selection: diff_selection} = assigns, socket) do
    changeset = DiffSelection.changeset(diff_selection)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)
     |> assign(:all_versions, PhxDiff.all_versions() |> Enum.map(&to_string/1))
     |> assign(
       :source_variants,
       variant_options_for_version(diff_selection.source)
     )
     |> assign(
       :target_variants,
       variant_options_for_version(diff_selection.target)
     )}
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
