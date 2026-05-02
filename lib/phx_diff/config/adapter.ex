defmodule PhxDiff.Config.Adapter do
  @moduledoc false

  @callback app_repo_path() :: String.t()
  @callback app_repo_store() :: module()
  @callback app_repo_cache_path() :: String.t()
  @callback app_repo_s3_bucket() :: String.t()
  @callback app_repo_s3_prefix() :: String.t()
  @callback app_repo_s3_region() :: String.t()
  @callback app_generator_workspace_path() :: String.t()
  @callback github_sample_app_base_url() :: String.t()
  @callback s3_base_url() :: String.t()
end
