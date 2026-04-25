defmodule PhxDiff.S3Simulator.StateServer do
  @moduledoc false

  use Agent

  alias PhxDiff.S3Simulator.StateServer.State

  @type put_object_opt :: {:content_type, String.t()} | {:if_none_match, String.t()}

  def start_link(_opts \\ []) do
    Agent.start_link(fn -> State.new() end)
  end

  @spec generate_credential(pid) :: map
  def generate_credential(server) do
    Agent.get_and_update(server, &State.generate_credential/1)
  end

  @spec fetch_secret_access_token(pid, String.t()) :: {:ok, String.t()} | :error
  def fetch_secret_access_token(server, access_key_id) do
    Agent.get(server, &State.fetch_secret_access_token(&1, access_key_id))
  end

  def create_bucket(server, bucket) do
    Agent.get_and_update(server, &State.create_bucket(&1, bucket))
  end

  @spec put_object(pid(), String.t(), String.t(), binary(), [put_object_opt()]) ::
          :ok | {:error, :no_such_bucket | :precondition_failed}
  def put_object(server, bucket, key, body, options) do
    Agent.get_and_update(server, &State.put_object(&1, bucket, key, body, options))
  end

  def fetch_object(server, bucket, key) do
    Agent.get(server, &State.fetch_object(&1, bucket, key))
  end

  def list_objects(server, bucket, prefix) do
    Agent.get(server, &State.list_objects(&1, bucket, prefix))
  end

  def delete_object(server, bucket, key) do
    Agent.get_and_update(server, &State.delete_object(&1, bucket, key))
  end

  def get_response_stub(server, operation) do
    Agent.get(server, &State.get_response_stub(&1, operation))
  end

  def stub_response(server, selector, response_id) do
    Agent.update(server, &State.stub_response(&1, selector, response_id))
  end

  def clear_stubbed_responses(server, selector) do
    Agent.update(server, &State.clear_stubbed_responses(&1, selector))
  end
end
