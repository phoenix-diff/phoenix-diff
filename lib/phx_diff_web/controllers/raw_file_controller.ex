defmodule PhxDiffWeb.RawFileController do
  use PhxDiffWeb, :controller

  alias PhxDiffWeb.Params

  defmodule NotFoundError do
    defexception plug_status: 404

    def message(_), do: "Not found"
  end

  def show(conn, %{"app_specification" => app_spec_slug, "path" => path_segments}) do
    relative_path = Path.join(path_segments)

    with {:ok, app_spec} <- Params.decode_app_spec(app_spec_slug),
         {:ok, content} <- read_file(app_spec, relative_path) do
      content_type = content_type_for(relative_path)

      conn
      |> put_resp_content_type(content_type, nil)
      |> send_resp(200, content)
    else
      :error -> raise NotFoundError
    end
  end

  defp read_file(app_spec, relative_path) do
    case PhxDiff.read_raw_app_file(app_spec, relative_path) do
      {:ok, content} -> {:ok, content}
      {:error, _} -> :error
    end
  end

  defp content_type_for(path) do
    case MIME.from_path(path) do
      "application/octet-stream" -> "text/plain"
      type -> type
    end
  end
end
