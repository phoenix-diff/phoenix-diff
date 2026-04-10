defmodule PhxDiff.Diffs do
  @moduledoc false

  alias PhxDiff.AppSpecification
  alias PhxDiff.ComparisonError
  alias PhxDiff.DiffManifest
  alias PhxDiff.DiffManifest.AddedFile
  alias PhxDiff.DiffManifest.BinaryAddedFile
  alias PhxDiff.DiffManifest.BinaryDeletedFile
  alias PhxDiff.DiffManifest.BinaryModifiedFile
  alias PhxDiff.DiffManifest.BinaryRenamedFile
  alias PhxDiff.DiffManifest.DeletedFile
  alias PhxDiff.DiffManifest.ModifiedFile
  alias PhxDiff.DiffManifest.PureRenamedFile
  alias PhxDiff.DiffManifest.RenamedFile
  alias PhxDiff.Diffs.AppRepo
  alias PhxDiff.Diffs.DiffEngine

  @type diff :: String.t()
  @type version :: Version.t()
  @type option :: String.t()

  @spec all_versions() :: [version]
  defdelegate all_versions, to: AppRepo

  @spec release_versions() :: [version]
  defdelegate release_versions, to: AppRepo

  @spec latest_version() :: version
  defdelegate latest_version, to: AppRepo

  @spec previous_release_version() :: version
  defdelegate previous_release_version, to: AppRepo

  @spec list_sample_apps_for_version(version) :: [AppSpecification.t()]
  defdelegate list_sample_apps_for_version(version), to: AppRepo

  @spec list_app_files(AppSpecification.t()) ::
          {:ok, [String.t()]} | {:error, :invalid_version}
  defdelegate list_app_files(app_spec), to: AppRepo

  @spec read_app_file(AppSpecification.t(), String.t()) ::
          {:ok, String.t()} | {:error, :invalid_version | :not_found | :binary_file}
  defdelegate read_app_file(app_spec, relative_path), to: AppRepo

  @spec read_raw_app_file(AppSpecification.t(), String.t()) ::
          {:ok, binary()} | {:error, :invalid_version | :not_found}
  defdelegate read_raw_app_file(app_spec, relative_path), to: AppRepo

  @spec generate_sample_app(AppSpecification.t()) ::
          {:ok, String.t()} | {:error, :unknown_version}
  defdelegate generate_sample_app(app_spec), to: AppRepo

  @spec get_github_sample_app_base_url(AppSpecification.t()) :: String.t()
  defdelegate get_github_sample_app_base_url(app_spec), to: AppRepo

  @spec default_app_specification(version) :: AppSpecification.t()
  def default_app_specification(%Version{} = version) do
    if Version.match?(version, "~> 1.5.0-rc.0", allow_pre: true) do
      AppSpecification.new(version, ["--live"])
    else
      AppSpecification.new(version, [])
    end
  end

  @spec fetch_diff_manifest(AppSpecification.t(), AppSpecification.t()) ::
          {:ok, DiffManifest.t()} | {:error, ComparisonError.t()}
  def fetch_diff_manifest(%AppSpecification{} = source_spec, %AppSpecification{} = target_spec) do
    case fetch_app_paths(source_spec, target_spec) do
      {:ok, source_path, target_path} ->
        {:ok, entries} = DiffEngine.compute_numstat(source_path, target_path)
        manifest = build_manifest(source_spec, target_spec, entries)
        {:ok, manifest}

      {:error, %ComparisonError{} = error} ->
        {:error, error}
    end
  end

  defp build_manifest(source_spec, target_spec, entries) do
    files =
      entries
      |> Enum.map(&build_file_entry/1)
      |> Enum.sort_by(& &1.path)

    non_binary = Enum.reject(files, &binary_entry?/1)
    total_added = Enum.sum(Enum.map(non_binary, &entry_added/1))
    total_deleted = Enum.sum(Enum.map(non_binary, &entry_deleted/1))

    %DiffManifest{
      source: source_spec,
      target: target_spec,
      total_files: length(files),
      total_added: total_added,
      total_deleted: total_deleted,
      files: files
    }
  end

  defp build_file_entry({stats, old_path, new_path}) do
    binary = stats == "-\t-\t"
    {added, deleted} = if binary, do: {0, 0}, else: parse_stats(stats)
    status = determine_status(old_path, new_path)
    path = canonical_path(status, old_path, new_path)

    build_struct(status, path, old_path, binary, added, deleted)
  end

  defp determine_status("/dev/null", _new_path), do: :added
  defp determine_status(_old_path, "/dev/null"), do: :deleted
  defp determine_status(old_path, new_path) when old_path != new_path, do: :renamed
  defp determine_status(_old_path, _new_path), do: :modified

  defp canonical_path(:added, _old, new), do: new
  defp canonical_path(:deleted, old, _new), do: old
  defp canonical_path(:renamed, _old, new), do: new
  defp canonical_path(:modified, old, _new), do: old

  defp parse_stats(stats) do
    [added_str, deleted_str, ""] = String.split(stats, "\t")
    {String.to_integer(added_str), String.to_integer(deleted_str)}
  end

  defp build_struct(:added, path, _old_path, true, _added, _deleted) do
    %BinaryAddedFile{path: path}
  end

  defp build_struct(:added, path, _old_path, false, added, _deleted) do
    %AddedFile{path: path, added: added}
  end

  defp build_struct(:deleted, path, _old_path, true, _added, _deleted) do
    %BinaryDeletedFile{path: path}
  end

  defp build_struct(:deleted, path, _old_path, false, _added, deleted) do
    %DeletedFile{path: path, deleted: deleted}
  end

  defp build_struct(:modified, path, _old_path, true, _added, _deleted) do
    %BinaryModifiedFile{path: path}
  end

  defp build_struct(:modified, path, _old_path, false, added, deleted) do
    %ModifiedFile{path: path, added: added, deleted: deleted}
  end

  defp build_struct(:renamed, path, old_path, true, _added, _deleted) do
    %BinaryRenamedFile{path: path, old_path: old_path}
  end

  defp build_struct(:renamed, path, old_path, false, 0, 0) do
    %PureRenamedFile{path: path, old_path: old_path}
  end

  defp build_struct(:renamed, path, old_path, false, added, deleted) do
    %RenamedFile{path: path, old_path: old_path, added: added, deleted: deleted}
  end

  defp binary_entry?(%BinaryAddedFile{}), do: true
  defp binary_entry?(%BinaryDeletedFile{}), do: true
  defp binary_entry?(%BinaryModifiedFile{}), do: true
  defp binary_entry?(%BinaryRenamedFile{}), do: true
  defp binary_entry?(_entry), do: false

  defp entry_added(%AddedFile{added: added}), do: added
  defp entry_added(%ModifiedFile{added: added}), do: added
  defp entry_added(%RenamedFile{added: added}), do: added
  defp entry_added(%PureRenamedFile{}), do: 0
  defp entry_added(%DeletedFile{}), do: 0

  defp entry_deleted(%DeletedFile{deleted: deleted}), do: deleted
  defp entry_deleted(%ModifiedFile{deleted: deleted}), do: deleted
  defp entry_deleted(%RenamedFile{deleted: deleted}), do: deleted
  defp entry_deleted(%PureRenamedFile{}), do: 0
  defp entry_deleted(%AddedFile{}), do: 0

  @spec fetch_diff(AppSpecification.t(), AppSpecification.t()) ::
          {:ok, diff} | {:error, ComparisonError.t()}
  def fetch_diff(%AppSpecification{} = source_spec, %AppSpecification{} = target_spec) do
    metadata = %{source_spec: source_spec, target_spec: target_spec}

    :telemetry.span([:phx_diff, :diffs, :generate], metadata, fn ->
      case fetch_app_paths(source_spec, target_spec) do
        {:ok, source_path, target_path} ->
          diff = DiffEngine.compute_diff(source_path, target_path)
          {{:ok, diff}, metadata}

        {:error, %ComparisonError{} = error} ->
          {{:error, error}, Map.put(metadata, :error, error)}
      end
    end)
  end

  defp fetch_app_paths(source_spec, target_spec) do
    [{:source, source_spec}, {:target, target_spec}]
    |> Enum.reduce({%{}, []}, fn {field, spec}, {paths, errors} ->
      case AppRepo.fetch_app_path(spec) do
        {:ok, path} ->
          {Map.put(paths, field, path), errors}

        {:error, :invalid_version} ->
          {paths, Keyword.put(errors, field, :unknown_version)}
      end
    end)
    |> case do
      {%{source: source_path, target: target_path}, _} ->
        {:ok, source_path, target_path}

      {_, errors} ->
        {:error,
         ComparisonError.exception(source: source_spec, target: target_spec, errors: errors)}
    end
  end
end
