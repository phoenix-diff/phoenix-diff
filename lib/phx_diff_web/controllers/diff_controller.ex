defmodule PhxDiffWeb.DiffController do
  use PhxDiffWeb, :controller

  alias PhxDiff.ComparisonError
  alias PhxDiffWeb.Params

  @cache_max_age_seconds :timer.hours(24) |> System.convert_time_unit(:millisecond, :second)

  defmodule NotFoundError do
    defexception plug_status: 404

    def message(_), do: "Not found"
  end

  defmodule InvalidParamsError do
    defexception plug_status: 400

    def message(_), do: "Bad Request"
  end

  def show(conn, %{"diff_specification" => diff_spec_slug} = params) do
    with {:ok, diff_spec} <- Params.decode_diff_spec(diff_spec_slug),
         {:ok, excludes} <- parse_excludes(params),
         {:ok, diff} <- PhxDiff.fetch_diff(diff_spec.source, diff_spec.target) do
      body = filter_diff(diff, excludes)

      conn
      |> put_resp_content_type("text/plain", nil)
      |> put_resp_header("content-disposition", ~s(inline; filename="#{diff_spec_slug}.diff"))
      |> put_resp_header("cache-control", "public, max-age=#{@cache_max_age_seconds}")
      |> send_resp(200, body)
    else
      :error -> raise NotFoundError
      {:error, %ComparisonError{}} -> raise NotFoundError
      {:error, :invalid_exclude} -> raise InvalidParamsError
    end
  end

  def stat(conn, %{"diff_specification" => diff_spec_slug}) do
    with {:ok, diff_spec} <- Params.decode_diff_spec(diff_spec_slug),
         {:ok, stat} <- PhxDiff.fetch_diff_stat(diff_spec.source, diff_spec.target) do
      conn
      |> put_resp_content_type("text/plain", nil)
      |> put_resp_header("cache-control", "public, max-age=#{@cache_max_age_seconds}")
      |> send_resp(200, stat)
    else
      :error -> raise NotFoundError
      {:error, %ComparisonError{}} -> raise NotFoundError
    end
  end

  defp parse_excludes(%{"exclude" => excludes}) when is_list(excludes) do
    if Enum.any?(excludes, &invalid_exclude?/1) do
      {:error, :invalid_exclude}
    else
      {:ok, excludes}
    end
  end

  defp parse_excludes(%{"exclude" => exclude}) when is_binary(exclude) do
    parse_excludes(%{"exclude" => [exclude]})
  end

  defp parse_excludes(_params), do: {:ok, []}

  defp invalid_exclude?(""), do: true

  defp invalid_exclude?(path) do
    path |> Path.split() |> Enum.any?(&(&1 in [".", ".."]))
  end

  defp filter_diff("", _excludes), do: ""
  defp filter_diff(diff, []), do: diff

  defp filter_diff(diff, excludes) do
    sections =
      diff
      |> String.replace_prefix("diff --git ", "")
      |> String.split("\ndiff --git ")

    sections
    |> Enum.reject(fn section ->
      path = extract_diff_path(section)
      Enum.any?(excludes, &path_excluded?(path, &1))
    end)
    |> Enum.map_join("\n", &("diff --git " <> &1))
  end

  # Extracts the repo-relative path from a diff section header.
  # The header line looks like: "a/path/to/file b/path/to/file\n..."
  # We take the b/ path (second path) and strip the "b/" prefix.
  defp extract_diff_path(section) do
    section
    |> String.split("\n", parts: 2)
    |> hd()
    |> then(fn header ->
      case String.split(header, " ") do
        [_a_path, b_path] -> String.replace_prefix(b_path, "b/", "")
        _ -> header
      end
    end)
  end

  defp path_excluded?(path, exclude) do
    path == exclude or String.starts_with?(path, exclude <> "/")
  end
end
