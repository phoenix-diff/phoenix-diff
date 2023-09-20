defmodule PhxDiffWeb.CompareLive.DiffViewerComponent.ParsedDiff.Patch do
  @moduledoc false

  import Bitwise

  alias PhxDiffWeb.CompareLive.DiffViewerComponent.Renderers

  defstruct [:display_filename, :display_filename_hash, :status, :html_anchor, :summary]

  @type t :: %__MODULE__{
          display_filename: String.t(),
          display_filename_hash: String.t(),
          status: status,
          html_anchor: String.t(),
          summary: summary
        }

  @type status :: :added | :removed | :renamed | :changed
  @type summary :: %{additions: non_neg_integer(), deletions: non_neg_integer()}

  @spec build(GitDiff.Patch.t()) :: t
  def build(%GitDiff.Patch{} = patch) do
    display_filename = Renderers.filename_diff(patch.from, patch.to)

    %__MODULE__{
      display_filename: display_filename,
      display_filename_hash: :crypto.hash(:sha256, display_filename) |> Base.url_encode64(),
      status: calculate_status(patch),
      html_anchor: d2h_html_id(display_filename),
      summary: calculate_summary(patch)
    }
  end

  defp calculate_status(%GitDiff.Patch{headers: %{"new file mode" => _}}), do: :added
  defp calculate_status(%GitDiff.Patch{headers: %{"deleted file mode" => _}}), do: :removed
  defp calculate_status(%GitDiff.Patch{headers: %{"rename from" => _}}), do: :renamed
  defp calculate_status(%GitDiff.Patch{}), do: :changed

  defp d2h_html_id(display_filename) do
    display_filename
    |> d2h_hashcode()
    |> to_string()
    |> String.slice(-6, 6)
    |> then(&"d2h-#{&1}")
  end

  defp d2h_hashcode(str) do
    # This is an elixir implemntation of
    # https://github.com/rtfpessoa/diff2html/blob/2c7e03d2660c0597eb15cc9db9ef652f57a1e224/src/utils.ts#L40-L54
    for char <- to_charlist(str), reduce: 0 do
      hash ->
        ((hash <<< 5) - hash + char)
        |> truncate_to_32bit_signed_integer()
    end
  end

  defp truncate_to_32bit_signed_integer(val) do
    <<n::integer-signed-size(32)>> = <<val::integer-signed-size(32)>>
    n
  end

  defp calculate_summary(patch) do
    for chunk <- patch.chunks,
        line <- chunk.lines,
        reduce: %{additions: 0, deletions: 0} do
      acc ->
        case line.type do
          :add -> Map.update!(acc, :additions, &(&1 + 1))
          :remove -> Map.update!(acc, :deletions, &(&1 + 1))
          _ -> acc
        end
    end
  end
end
