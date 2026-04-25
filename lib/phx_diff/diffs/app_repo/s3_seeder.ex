defmodule PhxDiff.Diffs.AppRepo.S3Seeder do
  @moduledoc false

  alias PhxDiff.AppSpecification
  alias PhxDiff.Diffs.AppRepo.AppSpecPath
  alias PhxDiff.Diffs.AppRepo.Archive
  alias PhxDiff.Diffs.AppRepo.Store.S3

  @type option :: {:force, boolean()} | {:version, String.t()} | {:variant, String.t()}
  @type status :: :uploaded | :skipped | :failed
  @type result :: %{
          app_spec: AppSpecification.t(),
          key: String.t(),
          path: String.t(),
          status: status
        }

  @spec seed([option]) :: {:ok, [result]} | {:error, :unable_to_list_local_apps}
  def seed(options) when is_list(options) do
    with {:ok, app_specs} <- local_app_specs(options) do
      results = Enum.map(app_specs, &seed_app(&1, options))

      {:ok, results}
    end
  end

  defp local_app_specs(options) do
    specs =
      PhxDiff.Config.app_repo_path()
      |> Path.join("*/*")
      |> Path.wildcard()
      |> Enum.map(&path_to_app_spec/1)
      |> Enum.filter(&matches_filters?(&1, options))
      |> Enum.sort_by(&AppSpecPath.path/1)

    {:ok, specs}
  rescue
    _ -> {:error, :unable_to_list_local_apps}
  end

  defp seed_app(%AppSpecification{} = app_spec, options) do
    status =
      with {:ok, false} <- maybe_existing_archive(app_spec, options),
           {:ok, archive} <- Archive.create(local_app_path(app_spec)),
           :ok <- S3.put_archive(app_spec, archive) do
        :uploaded
      else
        {:ok, true} -> :skipped
        _ -> :failed
      end

    %{
      app_spec: app_spec,
      key: S3.app_key(app_spec),
      path: AppSpecPath.path(app_spec),
      status: status
    }
  end

  defp maybe_existing_archive(app_spec, options) do
    if Keyword.get(options, :force, false),
      do: {:ok, false},
      else: S3.archive_exists?(app_spec)
  end

  defp matches_filters?(app_spec, options) do
    version_matches?(app_spec, options[:version]) and
      variant_matches?(app_spec, options[:variant])
  end

  defp version_matches?(_app_spec, nil), do: true
  defp version_matches?(app_spec, version), do: to_string(app_spec.phoenix_version) == version

  defp variant_matches?(_app_spec, nil), do: true

  defp variant_matches?(app_spec, variant),
    do: AppSpecPath.path(app_spec) |> Path.basename() == variant

  defp local_app_path(app_spec) do
    PhxDiff.Config.app_repo_path()
    |> Path.join(AppSpecPath.path(app_spec))
  end

  defp path_to_app_spec(path) do
    path
    |> Path.relative_to(PhxDiff.Config.app_repo_path())
    |> AppSpecPath.from_path()
  end
end
