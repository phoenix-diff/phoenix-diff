defmodule PhxDiffWeb.DiffController do
  use PhxDiffWeb, :controller

  alias PhxDiffWeb.Params

  @cache_max_age_seconds :timer.hours(24) |> System.convert_time_unit(:millisecond, :second)

  defmodule NotFoundError do
    defexception plug_status: 404
    def message(_), do: "Not found"
  end

  plug :register_no_store_on_error

  def show(conn, %{"diff_specification" => slug}) do
    include_prefixes =
      conn.query_string
      |> URI.query_decoder()
      |> Enum.filter(fn {k, _} -> k == "include" end)
      |> Enum.map(fn {_, v} -> v end)

    with {:ok, diff_spec} <- Params.decode_diff_spec(slug),
         {:ok, diff} <- PhxDiff.fetch_diff(diff_spec.source, diff_spec.target) do
      body = filter_diff(diff, include_prefixes)
      slug_label = Params.encode_diff_spec(diff_spec)

      conn
      |> put_resp_content_type("text/plain", "utf-8")
      |> put_resp_header("cache-control", "public, max-age=#{@cache_max_age_seconds}")
      |> put_resp_header("content-disposition", ~s(inline; filename="#{slug_label}.diff"))
      |> send_resp(200, body)
    else
      _ -> raise NotFoundError
    end
  end

  defp filter_diff(diff, []), do: diff

  defp filter_diff(diff, prefixes) do
    case PhxDiff.parse_diff(diff) do
      {:ok, patches} ->
        patches
        |> Enum.filter(&patch_matches_any?(&1, prefixes))
        |> PhxDiff.render_diff()

      _ ->
        diff
    end
  end

  defp patch_matches_any?(patch, prefixes) do
    paths =
      patch
      |> patch_paths()
      |> Enum.map(&strip_diff_prefix/1)

    Enum.any?(prefixes, fn prefix ->
      Enum.any?(paths, &String.starts_with?(&1, prefix))
    end)
  end

  defp patch_paths(%{from: from, to: to}), do: Enum.filter([from, to], &is_binary/1)

  defp strip_diff_prefix("a/" <> rest), do: rest
  defp strip_diff_prefix("b/" <> rest), do: rest
  defp strip_diff_prefix(path), do: path

  defp register_no_store_on_error(conn, _opts) do
    Plug.Conn.register_before_send(conn, fn conn ->
      if conn.status >= 400 do
        Plug.Conn.put_resp_header(conn, "cache-control", "no-store")
      else
        conn
      end
    end)
  end
end
