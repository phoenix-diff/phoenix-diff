defmodule PhxDiff.Diffs.AppRepo.Store do
  @moduledoc false

  @behaviour PhxDiff.Diffs.AppRepo.Store.Adapter

  alias PhxDiff.AppSpecification
  alias PhxDiff.AppStorageInfo

  @impl true
  @spec list_app_specs() :: {:ok, [AppSpecification.t()]}
  def list_app_specs do
    adapter().list_app_specs()
  end

  @impl true
  @spec list_app_specs_for_version(Version.t()) :: {:ok, [AppSpecification.t()]}
  def list_app_specs_for_version(%Version{} = version) do
    adapter().list_app_specs_for_version(version)
  end

  @impl true
  @spec fetch_app_path(AppSpecification.t()) :: {:ok, String.t()} | {:error, :invalid_version}
  def fetch_app_path(%AppSpecification{} = app_spec) do
    adapter().fetch_app_path(app_spec)
  end

  @impl true
  @spec store_generated_app(AppSpecification.t(), String.t()) ::
          {:ok, AppStorageInfo.t()}
  def store_generated_app(%AppSpecification{} = app_spec, source_path) do
    adapter().store_generated_app(app_spec, source_path)
  end

  defp adapter do
    PhxDiff.Config.app_repo_store()
  end
end
