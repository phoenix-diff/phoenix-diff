defmodule PhxDiffWeb.DiffManifestController do
  use PhxDiffWeb, :controller

  alias PhxDiffWeb.Params

  @cache_max_age_seconds :timer.hours(24) |> System.convert_time_unit(:millisecond, :second)

  defmodule NotFoundError do
    defexception plug_status: 404
    def message(_), do: "Not found"
  end

  # Runs before action/2 so the hook is on the conn captured by WrapperError
  plug :register_no_store_on_error

  def show(conn, %{"diff_specification" => slug}) do
    with {:ok, diff_spec} <- Params.decode_diff_spec(slug),
         {:ok, manifest} <- PhxDiff.fetch_diff_manifest(diff_spec.source, diff_spec.target) do
      conn
      |> put_resp_header("cache-control", "public, max-age=#{@cache_max_age_seconds}")
      |> render(:show, manifest: manifest)
    else
      _ -> raise NotFoundError
    end
  end

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
