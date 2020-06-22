defmodule PhxDiff.Diffs.DiffEngine do
  @moduledoc false

  alias PhxDiff.Diffs.AppRepo
  alias PhxDiff.Diffs.AppSpecification

  @type diff :: PhxDiff.Diffs.diff()

  @spec get_diff(AppSpecification.t(), AppSpecification.t()) ::
          {:ok, diff} | {:error, :invalid_versions}
  def get_diff(%AppSpecification{} = source_spec, %AppSpecification{} = target_spec) do
    with {:ok, source_path} <- AppRepo.fetch_app_path(source_spec),
         {:ok, target_path} <- AppRepo.fetch_app_path(target_spec) do
      diff = compute_diff!(source_path, target_path)
      {:ok, diff}
    else
      {:error, :invalid_version} -> {:error, :invalid_versions}
    end
  end

  @spec compute_diff!(String.t(), String.t()) :: diff
  defp compute_diff!(source_path, target_path) do
    {result, _exit_code} = System.cmd("diff", ["-ruN", source_path, target_path])

    result
    |> String.replace("#{source_path}/", "")
    |> String.replace("#{target_path}/", "")
  end
end
