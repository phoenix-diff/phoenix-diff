defmodule PhxDiff.S3Simulator.WebServer.CredentialValidator do
  @moduledoc false

  @behaviour Plug

  import Plug.Conn

  alias PhxDiff.S3Simulator.StateServer
  alias PhxDiff.S3Simulator.WebServer.Responses

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    case get_req_header(conn, "authorization") do
      [auth_header] when is_binary(auth_header) ->
        case validate_authorization(conn, auth_header) do
          :ok ->
            conn

          {:error, :invalid_access_key} ->
            conn
            |> send_error(
              403,
              "InvalidAccessKeyId",
              "The AWS access key ID you provided does not exist."
            )
            |> halt()

          {:error, :signature_mismatch} ->
            conn
            |> send_error(
              403,
              "SignatureDoesNotMatch",
              "The request signature we calculated does not match the signature you provided."
            )
            |> halt()
        end

      _ ->
        conn
        |> send_error(
          403,
          "MissingAuthenticationToken",
          "Request is missing authentication token."
        )
        |> halt()
    end
  end

  defp validate_authorization(conn, auth_header) do
    with {:ok, auth} <- parse_authorization(auth_header),
         {:ok, access_key, scope} <- parse_credential(auth["Credential"]),
         {:ok, secret_access_token} <- fetch_secret_access_token(conn, access_key),
         {:ok, expected_signature} <- signature(conn, auth, scope, secret_access_token),
         true <- secure_compare(auth["Signature"], expected_signature) do
      :ok
    else
      false -> {:error, :signature_mismatch}
      {:error, :invalid_access_key} -> {:error, :invalid_access_key}
      _ -> {:error, :signature_mismatch}
    end
  end

  defp fetch_secret_access_token(conn, access_key) do
    case StateServer.fetch_secret_access_token(conn.assigns.state_server, access_key) do
      {:ok, secret_access_token} -> {:ok, secret_access_token}
      :error -> {:error, :invalid_access_key}
    end
  end

  defp parse_authorization("AWS4-HMAC-SHA256 " <> params) do
    auth =
      params
      |> String.split(",")
      |> Map.new(fn param ->
        [key, value] = param |> String.trim() |> String.split("=", parts: 2)
        {key, value}
      end)

    if Map.has_key?(auth, "Credential") and Map.has_key?(auth, "SignedHeaders") and
         Map.has_key?(auth, "Signature") do
      {:ok, auth}
    else
      {:error, :invalid_authorization}
    end
  rescue
    MatchError -> {:error, :invalid_authorization}
  end

  defp parse_authorization(_auth_header), do: {:error, :invalid_authorization}

  defp parse_credential(nil), do: {:error, :invalid_access_key}

  defp parse_credential(credential) do
    case String.split(credential, "/") do
      [access_key, date, region, service, "aws4_request"] ->
        {:ok, access_key,
         %{
           date: date,
           region: region,
           service: service,
           scope: "#{date}/#{region}/#{service}/aws4_request"
         }}

      _ ->
        {:error, :invalid_access_key}
    end
  end

  defp signature(conn, auth, scope, secret_access_key) do
    with {:ok, amz_date} <- signed_header(conn, "x-amz-date"),
         {:ok, canonical_headers} <- canonical_headers(conn, auth["SignedHeaders"]) do
      canonical_request =
        Enum.join(
          [
            conn.method,
            canonical_uri(conn),
            canonical_query_string(conn),
            canonical_headers,
            auth["SignedHeaders"],
            payload_hash(conn)
          ],
          "\n"
        )

      string_to_sign = Enum.join(["AWS4-HMAC-SHA256", amz_date, scope.scope, sha256_hex(canonical_request)], "\n")

      {:ok, hmac_hex(signing_key(secret_access_key, scope), string_to_sign)}
    end
  end

  defp canonical_headers(conn, signed_headers) when is_binary(signed_headers) do
    conn_headers = Map.new(conn.req_headers)

    signed_headers
    |> String.split(";")
    |> Enum.map(fn header ->
      case conn_headers[header] do
        value when is_binary(value) -> {:ok, "#{header}:#{canonical_header_value(value)}\n"}
        _ -> {:error, :missing_signed_header}
      end
    end)
    |> Enum.reduce_while({:ok, []}, fn
      {:ok, header}, {:ok, headers} -> {:cont, {:ok, [header | headers]}}
      {:error, reason}, _ -> {:halt, {:error, reason}}
    end)
    |> case do
      {:ok, headers} -> {:ok, headers |> Enum.reverse() |> IO.iodata_to_binary()}
      {:error, reason} -> {:error, reason}
    end
  end

  defp canonical_headers(_conn, _signed_headers), do: {:error, :missing_signed_headers}

  defp canonical_header_value(value) do
    value
    |> String.trim()
    |> String.replace(~r/\s+/, " ")
  end

  defp canonical_uri(conn), do: conn.request_path

  defp canonical_query_string(%{query_string: ""}), do: ""

  defp canonical_query_string(conn) do
    conn.query_string
    |> URI.query_decoder()
    |> Enum.map(fn {key, value} -> {uri_encode(key), uri_encode(value)} end)
    |> Enum.sort()
    |> Enum.map_join("&", fn {key, value} -> "#{key}=#{value}" end)
  end

  defp payload_hash(conn) do
    case get_req_header(conn, "x-amz-content-sha256") do
      [hash] when is_binary(hash) -> hash
      _ -> sha256_hex("")
    end
  end

  defp signed_header(conn, header) do
    case get_req_header(conn, header) do
      [value] when is_binary(value) -> {:ok, value}
      _ -> {:error, :missing_signed_header}
    end
  end

  defp signing_key(secret_access_key, scope) do
    "AWS4#{secret_access_key}"
    |> hmac(scope.date)
    |> hmac(scope.region)
    |> hmac(scope.service)
    |> hmac("aws4_request")
  end

  defp hmac(key, data), do: :crypto.mac(:hmac, :sha256, key, data)

  defp hmac_hex(key, data), do: key |> hmac(data) |> Base.encode16(case: :lower)

  defp sha256_hex(data), do: :sha256 |> :crypto.hash(data) |> Base.encode16(case: :lower)

  defp secure_compare(left, right) when is_binary(left) and is_binary(right) and byte_size(left) == byte_size(right) do
    Plug.Crypto.secure_compare(left, right)
  end

  defp secure_compare(_left, _right), do: false

  defp uri_encode(value), do: URI.encode(value, &uri_unreserved?/1)

  defp uri_unreserved?(char) do
    char in ?A..?Z or char in ?a..?z or char in ?0..?9 or char in [?-, ?., ?_, ?~]
  end

  defp send_error(conn, status, code, message) do
    resource = "/" <> Enum.join(conn.path_info, "/")

    conn
    |> put_resp_content_type("application/xml")
    |> send_resp(status, Responses.render_error(code, message, resource))
  end
end
