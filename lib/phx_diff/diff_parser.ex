defmodule PhxDiff.DiffParser do
  @moduledoc false
  import NimbleParsec

  alias PhxDiff.Diff.Chunk
  alias PhxDiff.Diff.Line
  alias PhxDiff.Diff.Patch
  alias PhxDiff.DiffParser.HeaderLineParser

  rest_of_line = utf8_string([not: ?\n], min: 0)

  chunk_header =
    ignore(string("@@ -"))
    |> concat(integer(min: 1) |> unwrap_and_tag(:fs))
    |> optional(ignore(string(",")) |> concat(integer(min: 1) |> unwrap_and_tag(:fc)))
    |> ignore(string(" +"))
    |> concat(integer(min: 1) |> unwrap_and_tag(:ts))
    |> optional(ignore(string(",")) |> concat(integer(min: 1) |> unwrap_and_tag(:tc)))
    |> ignore(string(" @@"))
    |> concat(rest_of_line |> unwrap_and_tag(:ctx))

  defparsecp(:parse_chunk_header_tokens, chunk_header, inline: true)

  @doc """
  Parses a unified diff string into a list of patches.
  """
  @spec parse(String.t()) :: {:ok, [Patch.t()]} | {:error, :unrecognized_format}
  def parse(""), do: {:ok, []}

  def parse(diff) when is_binary(diff) do
    trailing_newline? = String.ends_with?(diff, "\n")

    with {:ok, state} <- diff |> split_lines() |> parse_lines({[], nil, nil}),
         result <- finalize(state) |> mark_trailing_newline(trailing_newline?),
         false <- result == [] do
      {:ok, result}
    else
      _ -> {:error, :unrecognized_format}
    end
  end

  @doc """
  Renders parsed patches back to the original diff string.
  """
  @spec to_string([Patch.t()]) :: String.t()
  def to_string(patches) when is_list(patches) do
    diff =
      patches
      |> Enum.map(&patch_to_lines/1)
      |> List.flatten()
      |> Enum.join("\n")

    case List.last(patches) do
      %Patch{trailing_newline: true} -> diff <> "\n"
      _ -> diff
    end
  end

  defp patch_to_lines(%Patch{} = patch) do
    chunk_lines =
      Enum.flat_map(patch.chunks, fn chunk ->
        [chunk.header | Enum.map(chunk.lines, & &1.raw)]
      end)

    patch.raw_headers ++ chunk_lines
  end

  defp split_lines(diff) do
    lines = :binary.split(diff, "\n", [:global])

    if String.ends_with?(diff, "\n") do
      Enum.drop(lines, -1)
    else
      lines
    end
  end

  defp mark_trailing_newline([], _trailing_newline?), do: []

  defp mark_trailing_newline(patches, trailing_newline?) do
    List.update_at(patches, -1, &%{&1 | trailing_newline: trailing_newline?})
  end

  defp parse_lines([], state), do: {:ok, state}

  defp parse_lines([line | rest], state) do
    with {:ok, next_state} <- process_line(line, state) do
      parse_lines(rest, next_state)
    end
  end

  # Patch start — always begins a new patch regardless of current state
  defp process_line(<<"diff --", _::binary>> = line, {patches, current_patch, current_chunk}),
    do:
      {:ok,
       {maybe_push_patch(patches, current_patch, current_chunk),
        %Patch{raw_headers: [line]} |> HeaderLineParser.parse_header_line(line), nil}}

  # Chunk header
  defp process_line(<<"@@", _::binary>> = line, {patches, current_patch, current_chunk}),
    do: {:ok, {patches, maybe_push_chunk(current_patch, current_chunk), parse_chunk_header(line)}}

  # Content lines (hot path) — dispatch on first byte when inside a chunk
  defp process_line(
         <<"+", _::binary>> = line,
         {patches, current_patch, %Chunk{} = current_chunk}
       ),
       do:
         {:ok,
          {patches, current_patch,
           %{current_chunk | lines: [parse_line(line) | current_chunk.lines]}}}

  defp process_line(
         <<"-", _::binary>> = line,
         {patches, current_patch, %Chunk{} = current_chunk}
       ),
       do:
         {:ok,
          {patches, current_patch,
           %{current_chunk | lines: [parse_line(line) | current_chunk.lines]}}}

  defp process_line(
         <<" ", _::binary>> = line,
         {patches, current_patch, %Chunk{} = current_chunk}
       ),
       do:
         {:ok,
          {patches, current_patch,
           %{current_chunk | lines: [parse_line(line) | current_chunk.lines]}}}

  defp process_line(
         <<"\\", _::binary>> = line,
         {patches, current_patch, %Chunk{} = current_chunk}
       ),
       do:
         {:ok,
          {patches, current_patch,
           %{current_chunk | lines: [parse_line(line) | current_chunk.lines]}}}

  defp process_line("" = line, {patches, current_patch, %Chunk{} = current_chunk}),
    do:
      {:ok,
       {patches, current_patch,
        %{current_chunk | lines: [parse_line(line) | current_chunk.lines]}}}

  defp process_line(_line, {_patches, _current_patch, %Chunk{}}), do: :error

  # Header line inside a patch, before the first chunk
  defp process_line(line, {patches, %Patch{} = current_patch, nil}),
    do:
      {:ok,
       {patches,
        current_patch |> HeaderLineParser.parse_header_line(line) |> prepend_raw_header(line),
        nil}}

  # Outside any patch context
  defp process_line(_line, state), do: {:ok, state}

  defp prepend_raw_header(%Patch{} = patch, line) do
    %{patch | raw_headers: [line | patch.raw_headers]}
  end

  defp maybe_push_patch(patches, nil, _current_chunk), do: patches

  defp maybe_push_patch(patches, %Patch{} = patch, current_chunk) do
    [finalize_patch(patch, current_chunk) | patches]
  end

  defp maybe_push_chunk(nil, _current_chunk), do: nil
  defp maybe_push_chunk(%Patch{} = patch, nil), do: patch

  defp maybe_push_chunk(%Patch{} = patch, %Chunk{} = chunk) do
    %{patch | chunks: [finalize_chunk(chunk) | patch.chunks]}
  end

  defp finalize({patches, current_patch, current_chunk}) do
    patches |> maybe_push_patch(current_patch, current_chunk) |> :lists.reverse()
  end

  defp finalize_patch(%Patch{} = patch, current_chunk) do
    patch = maybe_push_chunk(patch, current_chunk)

    %{
      patch
      | chunks: :lists.reverse(patch.chunks),
        raw_headers: :lists.reverse(patch.raw_headers)
    }
  end

  defp finalize_chunk(%Chunk{} = chunk), do: %{chunk | lines: :lists.reverse(chunk.lines)}

  defp parse_chunk_header(line) do
    case parse_chunk_header_tokens(line) do
      {:ok, result, _rest, _context, _position, _offset} ->
        {from_start, from_count, to_start, to_count, context} = chunk_header_fields(result)

        %Chunk{
          header: line,
          from_start: from_start,
          from_count: from_count,
          to_start: to_start,
          to_count: to_count,
          context: parse_context(context)
        }

      _ ->
        %Chunk{header: line}
    end
  end

  defp chunk_header_fields(tokens) do
    Enum.reduce(tokens, {0, 1, 0, 1, nil}, fn
      {:fs, value}, {_fs, fc, ts, tc, ctx} -> {value, fc, ts, tc, ctx}
      {:fc, value}, {fs, _fc, ts, tc, ctx} -> {fs, value, ts, tc, ctx}
      {:ts, value}, {fs, fc, _ts, tc, ctx} -> {fs, fc, value, tc, ctx}
      {:tc, value}, {fs, fc, ts, _tc, ctx} -> {fs, fc, ts, value, ctx}
      {:ctx, value}, {fs, fc, ts, tc, _ctx} -> {fs, fc, ts, tc, value}
    end)
  end

  defp parse_context(nil), do: nil
  defp parse_context(""), do: nil
  defp parse_context(" " <> ctx), do: ctx
  defp parse_context(ctx), do: ctx

  defp parse_line("+" <> text = raw), do: %Line{type: :add, text: text, raw: raw}
  defp parse_line("-" <> text = raw), do: %Line{type: :remove, text: text, raw: raw}
  defp parse_line(" " <> text = raw), do: %Line{type: :context, text: text, raw: raw}
  defp parse_line("\\" <> _ = raw), do: %Line{type: :no_newline, text: raw, raw: raw}
  # Handle empty context lines (a bare empty string from splitting)
  defp parse_line("" = raw), do: %Line{type: :context, text: "", raw: raw}
end
