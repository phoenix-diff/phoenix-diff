defmodule PhxDiffWeb.DiffManifestController do
  use PhxDiffWeb, :controller

  alias PhxDiffWeb.Params

  @cache_max_age_seconds :timer.hours(24) |> System.convert_time_unit(:millisecond, :second)

  defmodule NotFoundError do
    defexception plug_status: 404
    def message(_), do: "Not found"
  end

  defmodule ServiceUnavailableError do
    defexception plug_status: 503
    def message(_), do: "Service unavailable"
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
      {:error, %PhxDiff.ComparisonError{} = error} ->
        if storage_unavailable?(error),
          do: raise(ServiceUnavailableError),
          else: raise(NotFoundError)

      _ ->
        raise NotFoundError
    end
  end

  defp storage_unavailable?(%PhxDiff.ComparisonError{errors: errors}) do
    errors
    |> Keyword.values()
    |> Enum.any?(&(&1 == :storage_unavailable))
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
