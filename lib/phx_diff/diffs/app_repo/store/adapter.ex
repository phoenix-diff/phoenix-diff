defmodule PhxDiff.Diffs.AppRepo.Store.Adapter do
  @moduledoc false

  alias PhxDiff.AppSpecification

  @callback list_app_specs() :: {:ok, [AppSpecification.t()]}
  @callback list_app_specs_for_version(Version.t()) :: {:ok, [AppSpecification.t()]}
  @callback fetch_app_path(AppSpecification.t()) :: {:ok, String.t()} | {:error, :invalid_version}
  @callback store_generated_app(AppSpecification.t(), String.t()) :: {:ok, String.t()}
end
