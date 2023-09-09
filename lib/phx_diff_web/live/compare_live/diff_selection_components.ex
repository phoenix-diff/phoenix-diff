defmodule PhxDiffWeb.CompareLive.DiffSelectionComponents do
  @moduledoc false

  use PhxDiffWeb, :html

  @doc """
  Version selector on the homepage
  """
  attr :field, :any,
    doc: "a %Phoenix.HTML.Form{}/field name tuple, for example: {f, :source}",
    required: true

  attr :versions, :list, doc: "List of available versions", required: true
  attr :label, :string, doc: "The label to use on this component", required: true

  def version_select(assigns) do
    ~H"""
    <.input
      field={@field}
      type="select"
      label="Version"
      options={@versions}
      label_class="sr-only uppercase underline text-sm pr-2 sm:text-base"
      wrapper_class="inline-block sm:inline-flex sm:items-center"
      input_class="text-sm sm:mt-0"
    />
    """
  end

  @doc """
  PhxNewArgListPresets selector
  """
  attr :field, :any,
    doc: "a %Phoenix.HTML.Form{}/field name tuple, for example: {f, :source}",
    required: true

  attr :preset_options, :list, doc: "List of preset options", required: true
  attr :label, :string, doc: "The label to use on this component"

  def phx_new_arg_list_preset_select(assigns) do
    ~H"""
    <.input
      label="Arguments"
      field={@field}
      type="select"
      options={@preset_options}
      label_class="sr-only"
      wrapper_class="inline-block"
      input_class="text-sm sm:mt-0"
    />
    """
  end
end
