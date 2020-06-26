defmodule PhxDiff.Diffs do
  @moduledoc """
  Primary API for retrieving diffs
  """

  alias PhxDiff.Diffs.AppRepo
  alias PhxDiff.Diffs.AppSpecification
  alias PhxDiff.Diffs.DiffEngine

  @type diff :: String.t()
  @type version :: String.t()
  @type option :: String.t()

  @spec all_versions() :: [version]
  defdelegate all_versions, to: AppRepo

  @spec release_versions() :: [version]
  defdelegate release_versions, to: AppRepo

  @spec latest_version() :: version
  defdelegate latest_version, to: AppRepo

  @spec previous_release_version() :: version
  defdelegate previous_release_version, to: AppRepo

  @spec get_diff(AppSpecification.t(), AppSpecification.t()) ::
          {:ok, diff} | {:error, :invalid_versions}
  defdelegate get_diff(source_spec, target_spec), to: DiffEngine
end
