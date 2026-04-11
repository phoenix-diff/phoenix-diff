defmodule PhxDiff do
  @moduledoc """
  Primary API for interacting with PhxDiff
  """

  use Boundary,
    deps: [],
    exports: [
      AppSpecification,
      ComparisonError,
      DiffManifest,
      Diff.Patch,
      Diff.Chunk,
      Diff.Line,
      DiffManifest.AddedFile,
      DiffManifest.BinaryAddedFile,
      DiffManifest.BinaryDeletedFile,
      DiffManifest.BinaryModifiedFile,
      DiffManifest.BinaryRenamedFile,
      DiffManifest.DeletedFile,
      DiffManifest.ModifiedFile,
      DiffManifest.PureRenamedFile,
      DiffManifest.RenamedFile
    ]

  alias PhxDiff.AppSpecification
  alias PhxDiff.ComparisonError
  alias PhxDiff.DiffManifest

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
  Parse a unified diff string into a list of patches.
  """
  @spec parse_diff(diff) :: {:ok, [PhxDiff.Diff.Patch.t()]} | {:error, :unrecognized_format}
  defdelegate parse_diff(diff), to: PhxDiff.DiffParser, as: :parse

  @doc """
  Fetch the diff between two app specifications
  """
  @spec fetch_diff(AppSpecification.t(), AppSpecification.t()) ::
          {:ok, diff} | {:error, ComparisonError.t()}
  defdelegate fetch_diff(source_spec, target_spec), to: PhxDiff.Diffs

  @doc """
  Fetch a structured JSON manifest of file-level changes between two app specifications
  """
  @spec fetch_diff_manifest(AppSpecification.t(), AppSpecification.t()) ::
          {:ok, DiffManifest.t()} | {:error, ComparisonError.t()}
  defdelegate fetch_diff_manifest(source_spec, target_spec), to: PhxDiff.Diffs

  @doc """
  List all files for an app specification
  """
  @spec list_app_files(AppSpecification.t()) ::
          {:ok, [String.t()]} | {:error, :invalid_version}
  defdelegate list_app_files(app_spec), to: PhxDiff.Diffs

  @doc """
  Read a file from an app specification
  """
  @spec read_app_file(AppSpecification.t(), String.t()) ::
          {:ok, String.t()} | {:error, :invalid_version | :not_found | :binary_file}
  defdelegate read_app_file(app_spec, relative_path), to: PhxDiff.Diffs

  @doc """
  Read raw file bytes from an app specification, including binary files
  """
  @spec read_raw_app_file(AppSpecification.t(), String.t()) ::
          {:ok, binary()} | {:error, :invalid_version | :not_found}
  defdelegate read_raw_app_file(app_spec, relative_path), to: PhxDiff.Diffs

  @doc """
  Generates a sample application for the given app specification

  Returns the path of the generated app
  """
  @spec generate_sample_app(AppSpecification.t()) ::
          {:ok, String.t()} | {:error, :unknown_version}
  defdelegate generate_sample_app(app_spec), to: PhxDiff.Diffs

  @doc """
  Fetch the github url to the sample app for the given app specification
  """
  @spec get_github_sample_app_base_url(AppSpecification.t()) :: String.t()
  defdelegate get_github_sample_app_base_url(app_spec), to: PhxDiff.Diffs

  @doc """
  Lists the known app specs for a specific phoenix version
  """
  @spec list_sample_apps_for_version(Version.t()) :: [AppSpecification.t()]
  defdelegate list_sample_apps_for_version(version), to: PhxDiff.Diffs
end
