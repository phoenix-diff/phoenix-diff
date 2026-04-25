defmodule PhxDiff.S3Simulator.WebServer.Router do
  @moduledoc false

  use Plug.Router, copy_opts_to_assign: :init_opts

  alias PhxDiff.S3Simulator.StateServer
  alias PhxDiff.S3Simulator.WebServer.Responses

  plug :unpack_opts
  plug :match
  plug :fetch_query_params
  plug :assign_s3_operation
  plug :return_stubbed_responses
  plug :dispatch

  defp unpack_opts(conn, _opts) do
    conn.assigns.init_opts
    |> Keyword.validate!([:state_server])
    |> then(&merge_assigns(conn, &1))
  end

  put "/:bucket" do
    case StateServer.create_bucket(conn.assigns.state_server, bucket) do
      :ok -> send_resp(conn, 200, "")
    end
  end

  put "/:bucket/*key_parts" do
    key = key_from_parts(key_parts)
    {:ok, body, conn} = read_full_body(conn)

    case StateServer.put_object(conn.assigns.state_server, bucket, key, body, conn.req_headers) do
      :ok ->
        conn
        |> put_resp_header("etag", object_etag(body))
        |> send_resp(200, "")

      {:error, :no_such_bucket} ->
        send_error(conn, 404, "NoSuchBucket", "The specified bucket does not exist.")
    end
  end

  get "/:bucket" do
    case conn.query_params do
      %{"list-type" => "2"} = params ->
        prefix = Map.get(params, "prefix", "")

        case StateServer.list_objects(conn.assigns.state_server, bucket, prefix) do
          {:ok, objects} ->
            send_xml_resp(conn, 200, Responses.render_list_objects_v2(bucket, objects, prefix))

          {:error, :no_such_bucket} ->
            send_error(conn, 404, "NoSuchBucket", "The specified bucket does not exist.")
        end

      _params ->
        send_not_implemented(conn)
    end
  end

  get "/:bucket/*key_parts" do
    key = key_from_parts(key_parts)

    case StateServer.fetch_object(conn.assigns.state_server, bucket, key) do
      {:ok, object} ->
        conn
        |> put_resp_content_type(object.content_type)
        |> put_object_headers(object)
        |> send_resp(200, object.body)

      {:error, :no_such_bucket} ->
        send_error(conn, 404, "NoSuchBucket", "The specified bucket does not exist.")

      {:error, :no_such_key} ->
        send_error(conn, 404, "NoSuchKey", "The specified key does not exist.")
    end
  end

  head "/:bucket/*key_parts" do
    key = key_from_parts(key_parts)

    case StateServer.fetch_object(conn.assigns.state_server, bucket, key) do
      {:ok, object} ->
        conn
        |> put_object_headers(object)
        |> send_resp(200, "")

      {:error, :no_such_bucket} ->
        send_resp(conn, 404, "")

      {:error, :no_such_key} ->
        send_resp(conn, 404, "")
    end
  end

  delete "/:bucket/*key_parts" do
    key = key_from_parts(key_parts)

    case StateServer.delete_object(conn.assigns.state_server, bucket, key) do
      :ok ->
        send_resp(conn, 204, "")

      {:error, :no_such_bucket} ->
        send_error(conn, 404, "NoSuchBucket", "The specified bucket does not exist.")
    end
  end

  match _ do
    send_not_implemented(conn)
  end

  defp assign_s3_operation(conn, _opts) do
    assign(conn, :s3_operation, s3_operation(conn))
  end

  defp return_stubbed_responses(conn, _opts) do
    case stub_for(conn) do
      nil ->
        conn

      :internal_server_error ->
        conn
        |> send_error(500, "InternalError", "Internal Server Error")
        |> halt()

      :invalid_response ->
        conn
        |> send_invalid_response(conn.assigns.s3_operation.name)
        |> halt()
    end
  end

  defp stub_for(%{assigns: %{s3_operation: nil}}), do: nil

  defp stub_for(conn) do
    StateServer.get_response_stub(
      conn.assigns.state_server,
      conn.assigns.s3_operation
    )
  end

  defp read_full_body(conn, acc \\ []) do
    case read_body(conn) do
      {:ok, body, conn} -> {:ok, IO.iodata_to_binary([acc, body]), conn}
      {:more, body, conn} -> read_full_body(conn, [acc, body])
    end
  end

  defp put_object_headers(conn, object) do
    conn
    |> put_resp_header("etag", ~s("#{object.etag}"))
    |> put_resp_header(
      "last-modified",
      Calendar.strftime(object.last_modified, "%a, %d %b %Y %H:%M:%S GMT")
    )
    |> put_resp_header("content-length", Integer.to_string(object.size))
  end

  defp key_from_parts(key_parts), do: Enum.join(key_parts, "/")

  defp object_etag(body), do: ~s("#{Base.encode16(:crypto.hash(:md5, body), case: :lower)}")

  defp s3_operation(%{method: "PUT", path_info: [bucket]}) do
    %{name: :create_bucket, bucket: bucket}
  end

  defp s3_operation(%{method: "PUT", path_info: [bucket | key_parts]}) do
    %{name: :put_object, bucket: bucket, key: key_from_parts(key_parts)}
  end

  defp s3_operation(%{
         method: "GET",
         path_info: [bucket],
         query_params: %{"list-type" => "2"}
       }) do
    %{name: :list_objects, bucket: bucket}
  end

  defp s3_operation(%{method: "GET", path_info: [bucket | key_parts]}) do
    %{name: :get_object, bucket: bucket, key: key_from_parts(key_parts)}
  end

  defp s3_operation(%{method: "HEAD", path_info: [bucket | key_parts]}) do
    %{name: :head_object, bucket: bucket, key: key_from_parts(key_parts)}
  end

  defp s3_operation(%{method: "DELETE", path_info: [bucket | key_parts]}) do
    %{name: :delete_object, bucket: bucket, key: key_from_parts(key_parts)}
  end

  defp s3_operation(_conn), do: nil

  defp send_invalid_response(conn, :list_objects) do
    send_xml_resp(conn, 200, "Invalid")
  end

  defp send_invalid_response(conn, _operation_name) do
    send_xml_resp(conn, 500, "Invalid")
  end

  defp send_not_implemented(conn) do
    send_error(conn, 404, "NotImplemented", "The requested S3 operation is not implemented.")
  end

  defp send_error(conn, status, code, message) do
    resource = "/" <> Enum.join(conn.path_info, "/")
    send_xml_resp(conn, status, Responses.render_error(code, message, resource))
  end

  defp send_xml_resp(conn, status, body) do
    conn
    |> put_resp_content_type("application/xml")
    |> send_resp(status, body)
  end
end
