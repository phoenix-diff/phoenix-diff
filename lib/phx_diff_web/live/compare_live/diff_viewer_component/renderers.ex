defmodule PhxDiffWeb.CompareLive.DiffViewerComponent.Renderers do
  @moduledoc false

  @arrow_symbol "→"

  # Inspired by: https://github.com/rtfpessoa/diff2html/blob/09cbe8759583d0cc188dfb812ab91087b864d142/src/render-utils.ts#L123
  def filename_diff(nil, to) when is_binary(to), do: to
  def filename_diff(from, nil) when is_binary(from), do: from

  def filename_diff(from, to) when is_binary(from) and is_binary(to) do
    from_path_segments = Path.split(from)
    to_path_segments = Path.split(to)

    prefix_path_segments =
      Enum.zip([from_path_segments, to_path_segments])
      |> Enum.take_while(&match?({x, x}, &1))
      |> Enum.map(&elem(&1, 0))

    from_path_segments = from_path_segments -- prefix_path_segments
    to_path_segments = to_path_segments -- prefix_path_segments

    suffix_path_segments =
      Enum.zip([Enum.reverse(from_path_segments), Enum.reverse(to_path_segments)])
      |> Enum.take_while(&match?({x, x}, &1))
      |> Enum.map(&elem(&1, 0))
      |> Enum.reverse()

    from_path_segments =
      from_path_segments
      |> Enum.reverse()
      |> Kernel.--(suffix_path_segments)
      |> Enum.reverse()

    to_path_segments =
      to_path_segments
      |> Enum.reverse()
      |> Kernel.--(suffix_path_segments)
      |> Enum.reverse()

    case {prefix_path_segments, from_path_segments, to_path_segments, suffix_path_segments} do
      {[], [], [], []} ->
        # Blank paths
        ""

      {prefix_path_segments, [], [], []} ->
        # Identical paths
        Path.join(prefix_path_segments)

      {prefix_path_segments, [_ | _] = from_path_segments, [_ | _] = to_path_segments,
       suffix_path_segments}
      when length(prefix_path_segments) > 0 or length(suffix_path_segments) > 0 ->
        Path.join([
          maybe_join_path(prefix_path_segments),
          "{#{Path.join(from_path_segments)} #{@arrow_symbol} #{Path.join(to_path_segments)}}",
          maybe_join_path(suffix_path_segments)
        ])

      {_prefix_path_segments, _from_path_segments, _to_path_segments, _suffix_path_segments} ->
        "#{from} #{@arrow_symbol} #{to}"
    end
  end

  defp maybe_join_path([]), do: ""
  defp maybe_join_path(path_segments), do: Path.join(path_segments)
end
