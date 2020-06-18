defmodule PhxDiff.Diffs.DiffEngine do
  @moduledoc false

  alias PhxDiff.Diffs.AppRepo

  @type version :: PhxDiff.Diffs.version()
  @type diff :: PhxDiff.Diffs.diff()

  @spec get_diff(version, version) :: {:ok, diff} | {:error, :invalid_versions}
  def get_diff(source_version, target_version) do
    with {:ok, source_path} <- AppRepo.fetch_app_path(source_version),
         {:ok, target_path} <- AppRepo.fetch_app_path(target_version) do
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
