defmodule PhxDiff.Diffs.AppRepo.Store do
  @moduledoc false

  alias PhxDiff.AppSpecification

  @type fetch_error :: :invalid_version | :storage_unavailable
  @type store_error :: :storage_unavailable

  @callback list_app_specs() :: {:ok, [AppSpecification.t()]} | {:error, :storage_unavailable}
  @callback list_app_specs_for_version(Version.t()) ::
              {:ok, [AppSpecification.t()]} | {:error, :storage_unavailable}
  @callback fetch_app_path(AppSpecification.t()) :: {:ok, String.t()} | {:error, fetch_error}
  @callback store_generated_app(AppSpecification.t(), String.t()) ::
              {:ok, String.t()} | {:error, store_error}
end
