defmodule PhxDiffWeb.PageLive.DiffViewerComponent.ParsedDiff do
  @moduledoc false

  alias PhxDiffWeb.PageLive.DiffViewerComponent.ParsedDiff.Patch

  defstruct [:files_changed_count, patches: []]

  @type t :: %__MODULE__{files_changed_count: non_neg_integer(), patches: [Patch.t()]}

  @spec parse(String.t()) :: {:ok, t} | {:error, :unrecognized_format}
  def parse(diff) when is_binary(diff) do
    with {:ok, patches} <- GitDiff.parse_patch(diff) do
      {patches, count} =
        Enum.map_reduce(patches, 0, fn patch, acc -> {Patch.build(patch), acc + 1} end)

      {:ok, %__MODULE__{files_changed_count: count, patches: patches}}
    end
  end
end
