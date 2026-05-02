defmodule PhxDiff.Diffs.AppRepo.Archive do
  @moduledoc false

  @type create_error :: :empty | :archive_failed
  @type extract_error :: :empty | :invalid_archive

  @spec create(String.t()) :: {:ok, binary()} | {:error, create_error}
  def create(source_path) do
    with {:ok, files} <- files_to_archive(source_path),
         {:ok, archive_path} <- create_archive_file(source_path, files),
         {:ok, archive} <- File.read(archive_path) do
      File.rm(archive_path)
      {:ok, archive}
    else
      {:error, :empty} -> {:error, :empty}
      _ -> {:error, :archive_failed}
    end
  end

  @spec extract(binary(), String.t()) :: :ok | {:error, extract_error}
  def extract(archive, destination_path) when is_binary(archive) do
    with {:ok, entries} <- :erl_tar.table({:binary, archive}, [:compressed]),
         :ok <- validate_entries(entries, destination_path),
         :ok <- File.mkdir_p(destination_path),
         :ok <-
           :erl_tar.extract({:binary, archive}, [
             :compressed,
             {:cwd, String.to_charlist(destination_path)}
           ]) do
      :ok
    else
      {:error, :empty} -> {:error, :empty}
      _ -> {:error, :invalid_archive}
    end
  end

  defp files_to_archive(source_path) do
    files =
      source_path
      |> Path.join("**")
      |> Path.wildcard(match_dot: true)
      |> Enum.filter(&File.regular?/1)
      |> Enum.map(&Path.relative_to(&1, source_path))
      |> Enum.sort()

    case files do
      [] -> {:error, :empty}
      [_ | _] -> {:ok, files}
    end
  end

  defp create_archive_file(source_path, files) do
    archive_path =
      Path.join(System.tmp_dir!(), "phx-diff-app-#{System.unique_integer([:positive])}.tgz")

    case :erl_tar.open(String.to_charlist(archive_path), [:write, :compressed]) do
      {:ok, tar} -> write_archive(tar, archive_path, source_path, files)
      {:error, _reason} = error -> error
    end
  end

  defp write_archive(tar, archive_path, source_path, files) do
    case add_files(tar, source_path, files) do
      :ok ->
        case :erl_tar.close(tar) do
          :ok ->
            {:ok, archive_path}

          {:error, _reason} = error ->
            File.rm(archive_path)
            error
        end

      {:error, _reason} = error ->
        :erl_tar.close(tar)
        File.rm(archive_path)
        error
    end
  end

  defp add_files(tar, source_path, files) do
    Enum.reduce_while(files, :ok, fn file, :ok ->
      source_file = source_path |> Path.join(file) |> String.to_charlist()
      archive_file = String.to_charlist(file)

      case add_file(tar, source_file, archive_file) do
        :ok -> {:cont, :ok}
        {:error, _reason} = error -> {:halt, error}
      end
    end)
  end

  defp add_file(tar, source_file, archive_file) do
    case File.stat(source_file, access: :read) do
      {:ok, stat} ->
        if stat.access == :none do
          {:error, :eacces}
        else
          :erl_tar.add(tar, source_file, archive_file, [])
        end

      {:error, _reason} = error -> error
    end
  end

  defp validate_entries([], _destination_path), do: {:error, :empty}

  defp validate_entries(entries, destination_path) do
    destination_path = Path.expand(destination_path)

    if Enum.all?(entries, &safe_entry?(&1, destination_path)) do
      :ok
    else
      {:error, :invalid_archive}
    end
  end

  defp safe_entry?(entry, destination_path) do
    expanded_entry =
      entry
      |> to_string()
      |> Path.expand(destination_path)

    expanded_entry == destination_path or
      String.starts_with?(expanded_entry, destination_path <> "/")
  end
end
