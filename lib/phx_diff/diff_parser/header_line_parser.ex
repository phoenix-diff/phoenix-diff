defmodule PhxDiff.DiffParser.HeaderLineParser do
  @moduledoc false

  def parse_header_line(patch, "diff --git " <> rest) do
    case find_ab_split(rest) do
      {file_a, file_b} ->
        %{
          patch
          | from: file_a,
            to: file_b,
            headers: Map.merge(patch.headers, %{"file_a" => file_a, "file_b" => file_b})
        }

      nil ->
        patch
    end
  end

  def parse_header_line(patch, "diff --cc " <> file) do
    case parse_metadata_path(file) do
      nil -> patch
      file -> %{patch | from: file, to: file}
    end
  end

  def parse_header_line(patch, "diff --combined " <> file) do
    case parse_metadata_path(file) do
      nil -> patch
      file -> %{patch | from: file, to: file}
    end
  end

  def parse_header_line(patch, "--- " <> file), do: %{patch | from: parse_patch_path(file)}
  def parse_header_line(patch, "+++ " <> file), do: %{patch | to: parse_patch_path(file)}

  def parse_header_line(patch, "new file mode " <> mode) do
    %{patch | headers: Map.put(patch.headers, "new file mode", mode)}
  end

  def parse_header_line(patch, "deleted file mode " <> mode) do
    %{patch | headers: Map.put(patch.headers, "deleted file mode", mode)}
  end

  def parse_header_line(patch, "old mode " <> mode) do
    %{patch | headers: Map.put(patch.headers, "old mode", mode)}
  end

  def parse_header_line(patch, "new mode " <> mode) do
    %{patch | headers: Map.put(patch.headers, "new mode", mode)}
  end

  def parse_header_line(patch, "rename from " <> file) do
    file = parse_metadata_path(file)
    %{patch | from: file, headers: Map.put(patch.headers, "rename from", file)}
  end

  def parse_header_line(patch, "rename to " <> file) do
    file = parse_metadata_path(file)
    %{patch | to: file, headers: Map.put(patch.headers, "rename to", file)}
  end

  def parse_header_line(patch, "copy from " <> file) do
    file = parse_metadata_path(file)
    %{patch | from: file, headers: Map.put(patch.headers, "copy from", file)}
  end

  def parse_header_line(patch, "copy to " <> file) do
    file = parse_metadata_path(file)
    %{patch | to: file, headers: Map.put(patch.headers, "copy to", file)}
  end

  def parse_header_line(patch, "similarity index " <> value) do
    %{patch | headers: Map.put(patch.headers, "similarity index", value)}
  end

  def parse_header_line(patch, "dissimilarity index " <> value) do
    %{patch | headers: Map.put(patch.headers, "dissimilarity index", value)}
  end

  def parse_header_line(patch, "index " <> rest) do
    %{patch | headers: Map.put(patch.headers, "index", rest)}
  end

  def parse_header_line(patch, "GIT binary patch") do
    %{patch | headers: Map.put(patch.headers, "binary", true)}
  end

  def parse_header_line(patch, "Binary files " <> rest) do
    case parse_binary_paths(rest) do
      {from, to} ->
        %{
          patch
          | from: from,
            to: to,
            headers: Map.put(patch.headers, "binary", true)
        }

      nil ->
        %{patch | headers: Map.put(patch.headers, "binary", true)}
    end
  end

  def parse_header_line(patch, _line), do: patch

  # Find the split between file_a and file_b in a diff --git header.
  defp find_ab_split(rest) do
    if String.starts_with?(rest, "\"") do
      case parse_quoted_pair(rest, " ") do
        {file_a, file_b} -> {file_a, file_b}
        nil -> nil
      end
    else
      case String.replace_prefix(rest, "a/", "") |> split_unquoted_pair(" b/") do
        {file_a, file_b} -> {file_a, file_b}
        nil -> nil
      end
    end
  end

  defp parse_patch_path(file) do
    file
    |> strip_patch_metadata()
    |> parse_metadata_path()
  end

  defp strip_patch_metadata(file) do
    case String.split(file, "\t", parts: 2) do
      [path, _metadata] -> path
      [path] -> path
    end
  end

  defp parse_metadata_path("\"" <> _ = file) do
    case parse_quoted_path(file) do
      {path, ""} -> strip_diff_prefix(path)
      {path, remainder} when remainder == "\t" -> strip_diff_prefix(path)
      _ -> strip_diff_prefix(file)
    end
  end

  defp parse_metadata_path(file), do: strip_diff_prefix(file)

  defp parse_binary_paths(rest) do
    if String.starts_with?(rest, "\"") do
      parse_quoted_pair(String.replace_suffix(rest, " differ", ""), " and ")
    else
      case String.replace_suffix(rest, " differ", "") |> split_unquoted_pair(" and ") do
        {from, to} -> {parse_metadata_path(from), parse_metadata_path(to)}
        nil -> nil
      end
    end
  end

  defp parse_quoted_pair(string, separator) do
    with {left, remainder} <- parse_quoted_path(string),
         true <- String.starts_with?(remainder, separator),
         {right, ""} <- parse_quoted_path(String.replace_prefix(remainder, separator, "")) do
      {strip_diff_prefix(left), strip_diff_prefix(right)}
    else
      _ -> nil
    end
  end

  defp parse_quoted_path(string) do
    case Regex.run(~r/^"((?:[^"\\]|\\.)*)"(.*)$/u, string, capture: :all_but_first) do
      [path, remainder] -> {unescape_c_string(path), remainder}
      _ -> nil
    end
  end

  defp split_unquoted_pair(string, separator) do
    candidates =
      for {pos, _len} <- :binary.matches(string, separator) do
        left = binary_part(string, 0, pos)

        right =
          binary_part(
            string,
            pos + byte_size(separator),
            byte_size(string) - pos - byte_size(separator)
          )

        {left, right}
      end

    equal_candidates = Enum.filter(candidates, fn {left, right} -> left == right end)

    cond do
      equal_candidates != [] ->
        Enum.max_by(equal_candidates, fn {left, _right} -> byte_size(left) end)

      length(candidates) == 1 ->
        hd(candidates)

      true ->
        nil
    end
  end

  defp strip_diff_prefix("/dev/null"), do: nil
  defp strip_diff_prefix("a/" <> file), do: file
  defp strip_diff_prefix("b/" <> file), do: file
  defp strip_diff_prefix(other), do: other

  defp unescape_c_string(string), do: unescape_c_string(string, [])

  defp unescape_c_string("", acc), do: IO.iodata_to_binary(acc)

  defp unescape_c_string(<<"\\", d1, d2, d3, rest::binary>>, acc)
       when d1 in ?0..?7 and d2 in ?0..?7 and d3 in ?0..?7 do
    codepoint = (d1 - ?0) * 64 + (d2 - ?0) * 8 + (d3 - ?0)
    unescape_c_string(rest, [acc, <<codepoint>>])
  end

  defp unescape_c_string(<<"\\t", rest::binary>>, acc), do: unescape_c_string(rest, [acc, "\t"])
  defp unescape_c_string(<<"\\n", rest::binary>>, acc), do: unescape_c_string(rest, [acc, "\n"])
  defp unescape_c_string(<<"\\r", rest::binary>>, acc), do: unescape_c_string(rest, [acc, "\r"])
  defp unescape_c_string(<<"\\\"", rest::binary>>, acc), do: unescape_c_string(rest, [acc, "\""])
  defp unescape_c_string(<<"\\\\", rest::binary>>, acc), do: unescape_c_string(rest, [acc, "\\"])

  defp unescape_c_string(<<"\\", char::utf8, rest::binary>>, acc),
    do: unescape_c_string(rest, [acc, <<char::utf8>>])

  defp unescape_c_string(<<char::utf8, rest::binary>>, acc),
    do: unescape_c_string(rest, [acc, <<char::utf8>>])
end
