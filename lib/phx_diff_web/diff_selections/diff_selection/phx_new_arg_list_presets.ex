defmodule PhxDiffWeb.DiffSelections.DiffSelection.PhxNewArgListPresets do
  @moduledoc false

  alias PhxDiffWeb.DiffSelections.DiffSelection.PhxNewArgListPresets.PhxNewArgListPreset

  @mappings [
    default: [],
    no_ecto: ["--no-ecto"],
    live: ["--live"],
    no_live: ["--no-live"],
    no_html: ["--no-html"],
    binary_id: ["--binary-id"],
    umbrella: ["--umbrella"]
  ]

  for {id, arg_list} <- @mappings do
    def fetch(unquote(id)) do
      {:ok, %PhxNewArgListPreset{id: unquote(id), arg_list: unquote(arg_list)}}
    end
  end

  def fetch(_id), do: {:error, :not_found}

  @spec get_default_for_version(Version.t()) :: PhxNewArgListPreset.t()
  def get_default_for_version(%Version{} = version) do
    default_preset =
      version
      |> PhxDiff.default_app_specification()
      |> Map.fetch!(:phx_new_arguments)
      |> preset_from_arg_list!()

    known_presets = list_known_presets_for_version(version)

    if default_preset in known_presets do
      default_preset
    else
      known_presets
      |> Enum.sort_by(&priority_for_default_preset/1)
      |> List.first()
    end
  end

  @spec list_known_presets_for_version(Version.t()) :: [PhxNewArgListPreset.t()]
  def list_known_presets_for_version(%Version{} = version) do
    version
    |> PhxDiff.list_sample_apps_for_version()
    |> Enum.map(&preset_from_arg_list!(&1.phx_new_arguments))
  end

  for {id, arg_list} <- @mappings do
    def preset_from_arg_list(unquote(arg_list)) do
      {:ok, %PhxNewArgListPreset{id: unquote(id), arg_list: unquote(arg_list)}}
    end
  end

  def preset_from_arg_list(_) do
    :error
  end

  # A lower number returned means it will have higher priority in being used as the default variant
  for {{id, arg_list}, index} <- Enum.with_index(@mappings) do
    def priority_for_default_preset(%PhxNewArgListPreset{
          id: unquote(id),
          arg_list: unquote(arg_list)
        }),
        do: unquote(index)
  end

  # Highest number to make it the lowest priority
  def priority_for_default_preset(%PhxNewArgListPreset{}), do: 100

  def preset_from_arg_list!(arg_list) do
    case preset_from_arg_list(arg_list) do
      {:ok, preset} -> preset
      :error -> raise ArgumentError, "no preset for arg list: #{inspect(arg_list)}"
    end
  end
end
