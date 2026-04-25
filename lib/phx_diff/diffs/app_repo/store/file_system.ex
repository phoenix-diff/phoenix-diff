defmodule PhxDiff.Diffs.AppRepo.Store.FileSystem do
  @moduledoc false

  @behaviour PhxDiff.Diffs.AppRepo.Store

  alias PhxDiff.AppSpecification
  alias PhxDiff.Diffs.AppRepo.AppSpecPath

  @impl true
  def list_app_specs do
    specs =
      PhxDiff.Config.app_repo_path()
      |> Path.join("*/*")
      |> Path.wildcard()
      |> Enum.map(&path_to_app_spec/1)

    {:ok, specs}
  end

  @impl true
  def list_app_specs_for_version(%Version{} = version) do
    specs =
      PhxDiff.Config.app_repo_path()
      |> Path.join("#{version}/*")
      |> Path.wildcard()
      |> Enum.map(&path_to_app_spec/1)

    {:ok, specs}
  end

  @impl true
  def fetch_app_path(%AppSpecification{} = app_spec) do
    with {:ok, app_specs} <- list_app_specs() do
      if app_spec in app_specs do
        {:ok, app_path(app_spec)}
      else
        {:error, :invalid_version}
      end
    end
  end

  @impl true
  def store_generated_app(%AppSpecification{} = app_spec, source_path) do
    destination_path = app_path(app_spec)

    File.rm_rf(destination_path)
    File.mkdir_p!(destination_path)

    File.rename!(source_path, destination_path)

    {:ok, destination_path}
  end

  defp app_path(app_spec) do
    PhxDiff.Config.app_repo_path()
    |> Path.join(AppSpecPath.path(app_spec))
  end

  defp path_to_app_spec(path) do
    path
    |> Path.relative_to(PhxDiff.Config.app_repo_path())
    |> AppSpecPath.from_path()
  end
end
