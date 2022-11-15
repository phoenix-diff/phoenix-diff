defmodule PhxDiff do
  @moduledoc """
  Primary API for interacting with PhxDiff
  """

  use Boundary,
    deps: [],
    exports: [
      AppSpecification,
      ComparisonError
    ]

  alias PhxDiff.AppSpecification
  alias PhxDiff.ComparisonError

  @type diff :: String.t()
  @type version :: Version.t()

  @doc false
  defdelegate child_spec(opts), to: PhxDiff.Supervisor

  @doc """
  List all Phoenix versions
  """
  @spec all_versions() :: [version]
  defdelegate all_versions, to: PhxDiff.Diffs

  @doc """
  List all non-prerelease Phoenix versions
  """
  @spec release_versions() :: [version]
  defdelegate release_versions, to: PhxDiff.Diffs

  @doc """
  Get the latest Phoenix version
  """
  @spec latest_version() :: version
  defdelegate latest_version, to: PhxDiff.Diffs

  @doc """
  Get the version of the previous Phoenix release
  """
  @spec previous_release_version() :: version
  defdelegate previous_release_version, to: PhxDiff.Diffs

  @doc """
  Get the default app specification for a Phoenix version
  """
  @spec default_app_specification(version) :: AppSpecification.t()
  defdelegate default_app_specification(version), to: PhxDiff.Diffs

  @doc """
  Fetch the diff between two app specifications
  """
  @spec fetch_diff(AppSpecification.t(), AppSpecification.t()) ::
          {:ok, diff} | {:error, ComparisonError.t()}
  defdelegate fetch_diff(source_spec, target_spec), to: PhxDiff.Diffs, as: :get_diff

  @doc """
  Generates a sample application for the given app specification

  Returns the path of the generated app
  """
  @spec generate_sample_app(AppSpecification.t()) ::
          {:ok, String.t()} | {:error, :unknown_version}
  defdelegate generate_sample_app(app_spec), to: PhxDiff.Diffs
end
