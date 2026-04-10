defmodule PhxDiffWeb.DiffManifestJSON do
  alias PhxDiff.AppSpecification
  alias PhxDiff.DiffManifest
  alias PhxDiff.DiffManifest.AddedFile
  alias PhxDiff.DiffManifest.BinaryAddedFile
  alias PhxDiff.DiffManifest.BinaryDeletedFile
  alias PhxDiff.DiffManifest.BinaryModifiedFile
  alias PhxDiff.DiffManifest.BinaryRenamedFile
  alias PhxDiff.DiffManifest.DeletedFile
  alias PhxDiff.DiffManifest.ModifiedFile
  alias PhxDiff.DiffManifest.PureRenamedFile
  alias PhxDiff.DiffManifest.RenamedFile

  def show(%{manifest: %DiffManifest{} = manifest}) do
    %{
      source: app_spec(manifest.source),
      target: app_spec(manifest.target),
      total_files: manifest.total_files,
      total_added: manifest.total_added,
      total_deleted: manifest.total_deleted,
      files: Enum.map(manifest.files, &file_entry/1)
    }
  end

  defp app_spec(%AppSpecification{} = spec) do
    %{version: to_string(spec.phoenix_version), flags: spec.phx_new_arguments}
  end

  defp file_entry(%AddedFile{} = file) do
    %{"path" => file.path, "status" => "added", "added" => file.added, "deleted" => 0}
  end

  defp file_entry(%DeletedFile{} = file) do
    %{"path" => file.path, "status" => "deleted", "added" => 0, "deleted" => file.deleted}
  end

  defp file_entry(%ModifiedFile{} = file) do
    %{
      "path" => file.path,
      "status" => "modified",
      "added" => file.added,
      "deleted" => file.deleted
    }
  end

  defp file_entry(%RenamedFile{} = file) do
    %{
      "path" => file.path,
      "status" => "renamed",
      "old_path" => file.old_path,
      "added" => file.added,
      "deleted" => file.deleted
    }
  end

  defp file_entry(%BinaryAddedFile{} = file) do
    %{"path" => file.path, "status" => "added", "binary" => true}
  end

  defp file_entry(%BinaryDeletedFile{} = file) do
    %{"path" => file.path, "status" => "deleted", "binary" => true}
  end

  defp file_entry(%BinaryModifiedFile{} = file) do
    %{"path" => file.path, "status" => "modified", "binary" => true}
  end

  defp file_entry(%PureRenamedFile{} = file) do
    %{"path" => file.path, "status" => "renamed", "old_path" => file.old_path}
  end

  defp file_entry(%BinaryRenamedFile{} = file) do
    %{"path" => file.path, "status" => "renamed", "old_path" => file.old_path, "binary" => true}
  end
end
