defmodule PhxDiff.S3Simulator.StateServer do
  @moduledoc false

  use Agent

  alias PhxDiff.S3Simulator.StateServer.State

  def start_link(_opts \\ []) do
    Agent.start_link(fn -> State.new() end)
  end

  def create_bucket(server, bucket) do
    Agent.get_and_update(server, &State.create_bucket(&1, bucket))
  end

  def put_object(server, bucket, key, body, headers) do
    Agent.get_and_update(server, &State.put_object(&1, bucket, key, body, headers))
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
