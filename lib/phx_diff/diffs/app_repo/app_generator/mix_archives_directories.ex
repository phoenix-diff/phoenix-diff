defmodule PhxDiff.Diffs.AppRepo.AppGenerator.MixArchivesDirectories do
  @moduledoc false

  @type version :: String.t()
  @type path :: String.t()

  @spec fetch_path_for_phoenix_version(path, version) ::
          {:ok, path} | {:error, :invalid_version | :unknown_version}
  def fetch_path_for_phoenix_version(workspace_path, version) do
    with :ok <- validate_version(version) do
      find_or_create_mix_archives_path_for_phoenix_version(workspace_path, version)
    end
  end

  defp validate_version(version) do
    case Version.parse(version) do
      {:ok, _} -> :ok
      :error -> {:error, :invalid_version}
    end
  end

  defp find_or_create_mix_archives_path_for_phoenix_version(workspace_path, version) do
    archives_path = archives_repo_path_for_phoenix_version(workspace_path, version)

    if File.dir?(archives_path) do
      {:ok, archives_path}
    else
      create_archive_store(workspace_path, version)
    end
  end

  defp create_archive_store(workspace_path, version) do
    working_dir = generate_mix_archives_temp_path(workspace_path)
    File.mkdir_p!(working_dir)

    with :ok <- install_hex(working_dir),
         :ok <- install_phx_new(working_dir, version) do
      :ok = File.mkdir_p!(base_archives_repo_path(workspace_path))

      version_specific_archives_path =
        archives_repo_path_for_phoenix_version(workspace_path, version)

      :ok = File.rename!(working_dir, version_specific_archives_path)

      {:ok, version_specific_archives_path}
    end
  end

  defp install_hex(working_dir) do
    {_output, 0} =
      System.cmd("mix", ["local.hex", "--force"], env: [{"MIX_ARCHIVES", working_dir}])

    :ok
  end

  @spec install_phx_new(String.t(), String.t()) :: :ok | {:error, :unknown_version} | no_return
  defp install_phx_new(working_dir, version) do
    case System.cmd("mix", ["archive.install", "hex", "phx_new", version, "--force"],
           env: [{"MIX_ARCHIVES", working_dir}],
           stderr_to_stdout: true
         ) do
      {_output, 0} ->
        :ok

      {output, 1} ->
        if String.match?(output, ~r/no matching version/i) do
          {:error, :unknown_version}
        else
          raise """
          error occurred while installing phx_new

          #{output}
          """
        end
    end
  end

  defp archives_repo_path_for_phoenix_version(workspace_path, version) do
    workspace_path
    |> base_archives_repo_path()
    |> Path.join(version)
  end

  defp base_archives_repo_path(workspace_path) do
    Path.join([workspace_path, "mix_archives", "repo"])
  end

  defp generate_mix_archives_temp_path(workspace_path) do
    [workspace_path, "mix_archives", "tmp", random_string(16)]
    |> Path.join()
    |> Path.expand()
  end

  defp random_string(length) do
    length |> :crypto.strong_rand_bytes() |> Base.url_encode64() |> binary_part(0, length)
  end
end
