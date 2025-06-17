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
    <div class="inline-block">
      <label class="sr-only" for={@field.id}>Version</label>
      <.basic_select field={@field} options={@versions} />
    </div>
    """
  end

  @doc """
  PhxNewArgListPresets selector
  """
  attr :field, :any,
    doc: "a %Phoenix.HTML.Form{}/field name tuple, for example: {f, :source}",
    required: true

  attr :preset_options, :list, doc: "List of preset options", required: true
  attr :label, :string, doc: "The label to use on this component", required: true

  def phx_new_arg_list_preset_select(assigns) do
    ~H"""
    <div class="inline-block">
      <label class="sr-only" for={@field.id}>Arguments</label>
      <.basic_select field={@field} options={@preset_options} />
    </div>
    """
  end

  attr :field, :any,
    doc: "a %Phoenix.HTML.Form{}/field name tuple, for example: {f, :source}",
    required: true

  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"

  defp basic_select(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns =
      assigns
      |> assign(id: field.id)
      |> assign_new(:name, fn -> field.name end)
      |> assign_new(:value, fn -> field.value end)

    ~H"""
    <select id={@id} name={@name} class="w-full select">
      {Phoenix.HTML.Form.options_for_select(@options, @value)}
    </select>
    """
  end
end
