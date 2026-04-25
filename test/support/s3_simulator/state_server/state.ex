defmodule PhxDiff.S3Simulator.StateServer.State do
  @moduledoc false

  @type t :: map()
  @type put_object_opt :: {:content_type, String.t()} | {:if_none_match, String.t()}

  @spec new() :: t
  def new do
    %{
      credentials: %{},
      buckets: %{},
      response_stubs: %{}
    }
  end

  @spec generate_credential(t) :: {map, t}
  def generate_credential(state) do
    credential = %{
      access_key_id: random_token(),
      secret_access_token: random_token()
    }

    state = put_in(state.credentials[credential.access_key_id], credential.secret_access_token)

    {credential, state}
  end

  @spec fetch_secret_access_token(t, String.t()) :: {:ok, String.t()} | :error
  def fetch_secret_access_token(state, access_key_id) do
    Map.fetch(state.credentials, access_key_id)
  end

  def create_bucket(state, bucket) do
    bucket_state = %{objects: %{}, created_at: DateTime.utc_now()}
    state = put_in(state.buckets[bucket], Map.get(state.buckets, bucket, bucket_state))

    {:ok, state}
  end

  @spec put_object(t(), String.t(), String.t(), binary(), [put_object_opt()]) ::
          {:ok | {:error, :no_such_bucket | :precondition_failed}, t()}
  def put_object(state, bucket, key, body, options) do
    case fetch_bucket(state, bucket) do
      {:ok, bucket_state} ->
        if options[:if_none_match] == "*" and Map.has_key?(bucket_state.objects, key) do
          {{:error, :precondition_failed}, state}
        else
          object = %{
            key: key,
            body: body,
            content_type: Keyword.get(options, :content_type, "application/octet-stream"),
            etag: etag(body),
            last_modified: DateTime.utc_now(),
            size: byte_size(body)
          }

          bucket_state = put_in(bucket_state.objects[key], object)

          {:ok, put_in(state.buckets[bucket], bucket_state)}
        end

      {:error, :no_such_bucket} ->
        {{:error, :no_such_bucket}, state}
    end
  end

  def fetch_object(state, bucket, key) do
    with {:ok, bucket_state} <- fetch_bucket(state, bucket) do
      case Map.fetch(bucket_state.objects, key) do
        {:ok, object} -> {:ok, object}
        :error -> {:error, :no_such_key}
      end
    end
  end

  def list_objects(state, bucket, prefix) do
    with {:ok, bucket_state} <- fetch_bucket(state, bucket) do
      objects =
        bucket_state.objects
        |> Map.values()
        |> Enum.filter(&String.starts_with?(&1.key, prefix))
        |> Enum.sort_by(& &1.key)

      {:ok, objects}
    end
  end

  def delete_object(state, bucket, key) do
    case fetch_bucket(state, bucket) do
      {:ok, bucket_state} ->
        bucket_state = update_in(bucket_state.objects, &Map.delete(&1, key))

        {:ok, put_in(state.buckets[bucket], bucket_state)}

      {:error, :no_such_bucket} ->
        {{:error, :no_such_bucket}, state}
    end
  end

  def get_response_stub(state, operation) do
    operation
    |> selector_candidates()
    |> Enum.find_value(&state.response_stubs[&1])
  end

  def stub_response(state, selector, response_id) do
    response_stubs = Map.put(state.response_stubs, selector_key(selector), response_id)

    %{state | response_stubs: response_stubs}
  end

  def clear_stubbed_responses(state, selector) when selector == %{} do
    %{state | response_stubs: %{}}
  end

  def clear_stubbed_responses(state, selector) do
    Map.update!(state, :response_stubs, &Map.delete(&1, selector_key(selector)))
  end

  defp selector_candidates(operation) do
    operation_name = Map.fetch!(operation, :name)
    bucket = Map.fetch!(operation, :bucket)
    key = Map.get(operation, :key)

    Enum.uniq([
      {operation_name, bucket, key},
      {operation_name, nil, key},
      {nil, bucket, key},
      {operation_name, bucket, nil},
      {nil, nil, key},
      {nil, bucket, nil},
      {operation_name, nil, nil},
      {nil, nil, nil}
    ])
  end

  defp selector_key(selector) do
    {
      Map.get(selector, :operation),
      Map.get(selector, :bucket),
      Map.get(selector, :key)
    }
  end

  defp fetch_bucket(state, bucket) do
    case Map.fetch(state.buckets, bucket) do
      {:ok, bucket_state} -> {:ok, bucket_state}
      :error -> {:error, :no_such_bucket}
    end
  end

  defp etag(body) do
    :md5
    |> :crypto.hash(body)
    |> Base.encode16(case: :lower)
  end

  defp random_token do
    32
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end
end
