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
    version
    |> PhxDiff.default_app_specification()
    |> Map.fetch!(:phx_new_arguments)
    |> preset_from_arg_list()
  end

  @spec list_known_presets_for_version(Version.t()) :: [PhxNewArgListPreset.t()]
  def list_known_presets_for_version(%Version{} = version) do
    version
    |> PhxDiff.list_sample_apps_for_version()
    |> Enum.map(&preset_from_arg_list(&1.phx_new_arguments))
  end

  for {id, arg_list} <- @mappings do
    def preset_from_arg_list(unquote(arg_list)) do
      %PhxNewArgListPreset{id: unquote(id), arg_list: unquote(arg_list)}
    end
  end
end
