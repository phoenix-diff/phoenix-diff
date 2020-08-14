defmodule PhxDiff.Diffs.AppRepo.AppGenerator.MixArchivesDirectories do
  @moduledoc false

  @type version :: String.t()
  @type path :: String.t()

  @spec fetch_path_for_phoenix_version(path, version) ::
          {:ok, path} | {:error, :unknown_version}
  def fetch_path_for_phoenix_version(workspace_path, version) do
    validate_version!(version)
    find_or_create_mix_archives_path_for_phoenix_version(workspace_path, version)
  end

  defp validate_version!(version) do
    Version.parse!(version)
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

    with_tmp_dir(working_dir, fn ->
      with :ok <- install_hex(working_dir),
           :ok <- install_phx_new(working_dir, version) do
        move_to_archives_repo(workspace_path, version, working_dir)
      else
        {:error, :unknown_version} ->
          {:error, :unknown_version}
      end
    end)
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

  defp move_to_archives_repo(workspace_path, version, working_dir) do
    # Ensure archives repo root path exists
    :ok = File.mkdir_p!(archives_repo_path(workspace_path))

    version_specific_archives_path =
      archives_repo_path_for_phoenix_version(workspace_path, version)

    :ok = File.rename!(working_dir, version_specific_archives_path)

    {:ok, version_specific_archives_path}
  end

  defp archives_repo_path_for_phoenix_version(workspace_path, version) do
    workspace_path
    |> archives_repo_path()
    |> Path.join(version)
  end

  defp archives_repo_path(workspace_path) do
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

  defp with_tmp_dir(path, function) when is_binary(path) and is_function(function, 0) do
    File.mkdir_p!(path)

    function.()
  after
    File.rm_rf(path)
  end
end
