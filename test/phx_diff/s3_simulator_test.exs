defmodule PhxDiff.S3SimulatorTest do
  use PhxDiff.MockedConfigCase, async: true

  alias ExAws.S3
  alias PhxDiff.S3Simulator

  setup [{PhxDiff.SimulatorHelpers, :configure_for_s3_simulator}]

  test "supports core S3 object operations", %{aws_config: aws_config} do
    bucket = unique_bucket_name()

    assert {:ok, _response} = S3.put_bucket(bucket, "us-east-1") |> request(aws_config)

    assert {:ok, _response} =
             S3.put_object(bucket, "documents/hello.txt", "Hello S3", content_type: "text/plain")
             |> request(aws_config)

    assert {:ok, %{body: "Hello S3"}} =
             S3.get_object(bucket, "documents/hello.txt") |> request(aws_config)

    assert {:ok, %{status_code: 200}} =
             S3.head_object(bucket, "documents/hello.txt") |> request(aws_config)

    assert {:ok, _response} =
             S3.put_object(bucket, "images/logo.png", "PNG") |> request(aws_config)

    assert {:ok, response} = S3.list_objects_v2(bucket) |> request(aws_config)
    assert object_keys(response) == ["documents/hello.txt", "images/logo.png"]

    assert {:ok, response} =
             S3.list_objects_v2(bucket, prefix: "documents/") |> request(aws_config)

    assert object_keys(response) == ["documents/hello.txt"]

    assert {:ok, %{status_code: 204}} =
             S3.delete_object(bucket, "documents/hello.txt") |> request(aws_config)

    assert {:error, _} = S3.get_object(bucket, "documents/hello.txt") |> request(aws_config)

    assert {:ok, response} = S3.list_objects_v2(bucket) |> request(aws_config)
    assert object_keys(response) == ["images/logo.png"]
  end

  test "rejects requests signed with an invalid secret access key", %{aws_config: aws_config} do
    aws_config = Keyword.put(aws_config, :secret_access_key, "wrong-secret")

    assert {:error, _reason} =
             S3.put_bucket(unique_bucket_name(), "us-east-1") |> request(aws_config)
  end

  test "supports multiple generated credential pairs", %{
    s3_simulator: sim,
    aws_config: aws_config
  } do
    credential = S3Simulator.generate_credential(sim)

    other_aws_config =
      aws_config
      |> Keyword.put(:access_key_id, credential.access_key_id)
      |> Keyword.put(:secret_access_key, credential.secret_access_token)

    assert {:ok, _response} =
             S3.put_bucket(unique_bucket_name(), "us-east-1") |> request(aws_config)

    assert {:ok, _response} =
             S3.put_bucket(unique_bucket_name(), "us-east-1") |> request(other_aws_config)
  end

  test "allows for closing and reopening a connection", %{
    s3_simulator: sim,
    aws_config: aws_config
  } do
    bucket = unique_bucket_name()

    assert {:ok, _response} = S3.put_bucket(bucket, "us-east-1") |> request(aws_config)

    S3Simulator.down(sim)

    assert {:error, _} = S3.list_objects_v2(bucket) |> request(aws_config)

    S3Simulator.up(sim)

    assert {:ok, _response} = S3.list_objects_v2(bucket) |> request(aws_config)
  end

  test "triggering and clearing stubbed responses", %{s3_simulator: sim, aws_config: aws_config} do
    bucket = unique_bucket_name()

    assert {:ok, _response} = S3.put_bucket(bucket, "us-east-1") |> request(aws_config)

    assert {:ok, _response} =
             S3.put_object(bucket, "documents/hello.txt", "Hello S3") |> request(aws_config)

    S3Simulator.trigger_internal_server_errors(sim, operation: :list_objects)

    assert {:error, _} = S3.list_objects_v2(bucket) |> request(aws_config)

    S3Simulator.clear_stubbed_responses(sim, operation: :list_objects)

    assert {:ok, response} = S3.list_objects_v2(bucket) |> request(aws_config)
    assert object_keys(response) == ["documents/hello.txt"]

    S3Simulator.trigger_invalid_responses(sim, operation: :create_bucket)

    assert request_fails?(fn ->
             S3.put_bucket(unique_bucket_name(), "us-east-1") |> request(aws_config)
           end)

    S3Simulator.clear_stubbed_responses(sim, operation: :create_bucket)
    S3Simulator.trigger_internal_server_errors(sim, operation: :get_object)

    assert {:error, _} = S3.get_object(bucket, "documents/hello.txt") |> request(aws_config)

    S3Simulator.clear_stubbed_responses(sim, operation: :get_object)

    S3Simulator.trigger_invalid_responses(sim, operation: :list_objects)

    assert request_fails?(fn ->
             S3.list_objects_v2(bucket) |> request(aws_config)
           end)

    S3Simulator.clear_stubbed_responses(sim, operation: :list_objects)

    S3Simulator.trigger_internal_server_errors(sim)

    assert {:error, _} = S3.list_objects_v2(bucket) |> request(aws_config)
  end

  test "stubs responses for a single bucket", %{s3_simulator: sim, aws_config: aws_config} do
    bucket = unique_bucket_name()
    other_bucket = unique_bucket_name()

    assert {:ok, _response} = S3.put_bucket(bucket, "us-east-1") |> request(aws_config)
    assert {:ok, _response} = S3.put_bucket(other_bucket, "us-east-1") |> request(aws_config)

    S3Simulator.trigger_internal_server_errors(sim, bucket: bucket)

    assert {:error, _} = S3.list_objects_v2(bucket) |> request(aws_config)
    assert {:ok, _response} = S3.list_objects_v2(other_bucket) |> request(aws_config)

    S3Simulator.clear_stubbed_responses(sim, bucket: bucket)

    assert {:ok, _response} = S3.list_objects_v2(bucket) |> request(aws_config)
  end

  test "stubs responses for a single key across object operations", %{
    s3_simulator: sim,
    aws_config: aws_config
  } do
    bucket = unique_bucket_name()
    key = "documents/hello.txt"

    assert {:ok, _response} = S3.put_bucket(bucket, "us-east-1") |> request(aws_config)

    assert {:ok, _response} =
             S3.put_object(bucket, key, "Hello S3") |> request(aws_config)

    assert {:ok, _response} =
             S3.put_object(bucket, "documents/other.txt", "Other") |> request(aws_config)

    S3Simulator.trigger_internal_server_errors(sim, key: key)

    assert {:error, _} = S3.get_object(bucket, key) |> request(aws_config)
    assert {:error, _} = S3.head_object(bucket, key) |> request(aws_config)
    assert {:error, _} = S3.put_object(bucket, key, "Updated") |> request(aws_config)
    assert {:error, _} = S3.delete_object(bucket, key) |> request(aws_config)

    assert {:ok, %{body: "Other"}} =
             S3.get_object(bucket, "documents/other.txt") |> request(aws_config)

    S3Simulator.clear_stubbed_responses(sim, key: key)

    assert {:ok, %{body: "Hello S3"}} = S3.get_object(bucket, key) |> request(aws_config)
  end

  test "stubs responses for a single operation on a single key", %{
    s3_simulator: sim,
    aws_config: aws_config
  } do
    bucket = unique_bucket_name()
    key = "documents/hello.txt"

    assert {:ok, _response} = S3.put_bucket(bucket, "us-east-1") |> request(aws_config)

    assert {:ok, _response} =
             S3.put_object(bucket, key, "Hello S3") |> request(aws_config)

    S3Simulator.trigger_internal_server_errors(sim, operation: :get_object, key: key)

    assert {:error, _} = S3.get_object(bucket, key) |> request(aws_config)
    assert {:ok, %{status_code: 200}} = S3.head_object(bucket, key) |> request(aws_config)

    S3Simulator.clear_stubbed_responses(sim, operation: :get_object, key: key)

    assert {:ok, %{body: "Hello S3"}} = S3.get_object(bucket, key) |> request(aws_config)
  end

  test "clears one selector without clearing broader stubs", %{
    s3_simulator: sim,
    aws_config: aws_config
  } do
    bucket = unique_bucket_name()
    key = "documents/hello.txt"

    assert {:ok, _response} = S3.put_bucket(bucket, "us-east-1") |> request(aws_config)

    assert {:ok, _response} =
             S3.put_object(bucket, key, "Hello S3") |> request(aws_config)

    S3Simulator.trigger_internal_server_errors(sim, bucket: bucket)
    S3Simulator.trigger_invalid_responses(sim, operation: :get_object, key: key)
    S3Simulator.clear_stubbed_responses(sim, operation: :get_object, key: key)

    assert {:error, _} = S3.get_object(bucket, key) |> request(aws_config)

    S3Simulator.clear_stubbed_responses(sim, bucket: bucket)

    assert {:ok, %{body: "Hello S3"}} = S3.get_object(bucket, key) |> request(aws_config)
  end

  test "rejects atom stubbing selectors", %{s3_simulator: sim} do
    assert_raise FunctionClauseError, fn ->
      S3Simulator.trigger_internal_server_errors(sim, :get_object)
    end
  end

  defp request(operation, aws_config) do
    ExAws.request(operation, aws_config)
  end

  defp request_fails?(fun) when is_function(fun, 0) do
    case fun.() do
      {:error, _reason} -> true
      {:ok, _response} -> false
    end
  catch
    :exit, _reason -> true
  end

  defp object_keys(%{body: %{contents: contents}}) when is_list(contents) do
    contents
    |> Enum.map(&object_key/1)
    |> Enum.reject(&is_nil/1)
  end

  defp object_keys(%{body: contents}) when is_list(contents) do
    contents
    |> Enum.map(&object_key/1)
    |> Enum.reject(&is_nil/1)
  end

  defp object_keys(%{body: %{}}), do: []

  defp object_key(object) when is_map(object) do
    object[:key] || object["key"] || object[:Key] || object["Key"]
  end

  defp unique_bucket_name do
    "test-bucket-#{System.unique_integer([:positive])}"
  end
end
