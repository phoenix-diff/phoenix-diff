defmodule PhxDiffWeb.FileListController do
  use PhxDiffWeb, :controller

  alias PhxDiffWeb.Params

  @cache_max_age_seconds :timer.hours(24) |> System.convert_time_unit(:millisecond, :second)

  defmodule NotFoundError do
    defexception plug_status: 404

    def message(_), do: "Not found"
  end

  def index(conn, %{"app_specification" => app_spec_slug}) do
    with {:ok, app_spec} <- Params.decode_app_spec(app_spec_slug),
         {:ok, files} <- PhxDiff.list_app_files(app_spec) do
      body = Enum.join(files, "\n") <> "\n"

      conn
      |> put_resp_content_type("text/plain", nil)
      |> put_resp_header("cache-control", "public, max-age=#{@cache_max_age_seconds}")
      |> send_resp(200, body)
    else
      _ -> raise NotFoundError
    end
  end
end
