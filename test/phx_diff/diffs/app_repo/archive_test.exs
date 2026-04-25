defmodule PhxDiff.Diffs.AppRepo.ArchiveTest do
  use ExUnit.Case, async: false

  alias PhxDiff.Diffs.AppRepo.Archive

  describe "create/1 and extract/2" do
    @tag :tmp_dir
    test "round-trips text files, binary files, dotfiles, and nested files", %{tmp_dir: tmp_dir} do
      source_path = Path.join(tmp_dir, "source")
      destination_path = Path.join(tmp_dir, "destination")

      File.mkdir_p!(Path.join(source_path, "lib/nested"))
      File.write!(Path.join(source_path, "README.md"), "hello")
      File.write!(Path.join(source_path, ".formatter.exs"), "[]")
      File.write!(Path.join(source_path, "lib/nested/file.ex"), "defmodule Sample do\nend\n")
      File.write!(Path.join(source_path, "favicon.ico"), <<0, 1, 2, 3>>)

      assert {:ok, archive} = Archive.create(source_path)
      assert :ok = Archive.extract(archive, destination_path)

      assert File.read!(Path.join(destination_path, "README.md")) == "hello"
      assert File.read!(Path.join(destination_path, ".formatter.exs")) == "[]"

      assert File.read!(Path.join(destination_path, "lib/nested/file.ex")) ==
               "defmodule Sample do\nend\n"

      assert File.read!(Path.join(destination_path, "favicon.ico")) == <<0, 1, 2, 3>>
    end

    @tag :tmp_dir
    test "returns an error when creating an archive from an empty directory", %{tmp_dir: tmp_dir} do
      source_path = Path.join(tmp_dir, "source")
      File.mkdir_p!(source_path)

      assert {:error, :empty} = Archive.create(source_path)
    end

    @tag :tmp_dir
    test "removes the partial archive when adding a file fails", %{tmp_dir: tmp_dir} do
      existing_archive_tmp_files = archive_tmp_files()

      source_path = Path.join(tmp_dir, "source")
      unreadable_path = Path.join(source_path, "b-unreadable.txt")

      File.mkdir_p!(source_path)
      File.write!(Path.join(source_path, "a-readable.txt"), "ok")
      File.write!(unreadable_path, "blocked")
      File.chmod!(unreadable_path, 0)

      on_exit(fn ->
        File.chmod(unreadable_path, 0o600)
        remove_archive_tmp_files(existing_archive_tmp_files)
      end)

      assert {:error, :archive_failed} = Archive.create(source_path)
      assert new_archive_tmp_files(existing_archive_tmp_files) == []
    end

    @tag :tmp_dir
    test "returns an error when extracting an empty archive", %{tmp_dir: tmp_dir} do
      archive = create_test_archive(tmp_dir, [])

      assert {:error, :empty} = Archive.extract(archive, Path.join(tmp_dir, "destination"))
    end

    @tag :tmp_dir
    test "rejects archive entries that escape the destination", %{tmp_dir: tmp_dir} do
      archive = create_test_archive(tmp_dir, [{"../escape.txt", "bad"}])

      assert {:error, :invalid_archive} =
               Archive.extract(archive, Path.join(tmp_dir, "destination"))

      refute File.exists?(Path.join(tmp_dir, "escape.txt"))
    end
  end

  defp create_test_archive(tmp_dir, entries) do
    archive_path = Path.join(tmp_dir, "test.tgz")
    {:ok, tar} = :erl_tar.open(String.to_charlist(archive_path), [:write, :compressed])

    Enum.each(entries, fn {name, content} ->
      file_path = Path.join(tmp_dir, "fixture-#{System.unique_integer([:positive])}")
      File.write!(file_path, content)
      :ok = :erl_tar.add(tar, String.to_charlist(file_path), String.to_charlist(name), [])
    end)

    :ok = :erl_tar.close(tar)
    File.read!(archive_path)
  end

  defp archive_tmp_files do
    System.tmp_dir!()
    |> Path.join("phx-diff-app-*.tgz")
    |> Path.wildcard()
    |> MapSet.new()
  end

  defp new_archive_tmp_files(existing_archive_tmp_files) do
    archive_tmp_files()
    |> MapSet.difference(existing_archive_tmp_files)
    |> MapSet.to_list()
  end

  defp remove_archive_tmp_files(existing_archive_tmp_files) do
    Enum.each(new_archive_tmp_files(existing_archive_tmp_files), &File.rm/1)
  end
end
