defmodule PhxDiff.S3Simulator do
  @moduledoc """
  An S3 simulator.
  """

  alias PhxDiff.S3Simulator.PortCache
  alias PhxDiff.S3Simulator.StateServer
  alias PhxDiff.S3Simulator.WebServer

  @operations [
    :create_bucket,
    :put_object,
    :get_object,
    :head_object,
    :list_objects,
    :delete_object
  ]

  @type t :: pid

  @type operation ::
          :create_bucket
          | :put_object
          | :get_object
          | :head_object
          | :list_objects
          | :delete_object

  @type selector_opt :: {:operation, operation} | {:bucket, String.t()} | {:key, String.t()}

  @doc false
  def child_spec(init_arg) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [init_arg]},
      type: :supervisor
    }
  end

  @doc """
  Start an instance linked to the current test process.
  """
  @spec start_link(keyword) :: Supervisor.on_start()
  def start_link(_opts) do
    with {:ok, sup} <- Supervisor.start_link([], strategy: :rest_for_one) do
      {:ok, _} = Application.ensure_all_started(:bandit)

      {:ok, port_cache} = Supervisor.start_child(sup, PortCache)
      {:ok, state_server} = Supervisor.start_child(sup, StateServer)

      {:ok, _web_server} =
        Supervisor.start_child(
          sup,
          {WebServer, port_cache: port_cache, state_server: state_server}
        )

      {:ok, sup}
    end
  end

  @doc """
  Close the simulator's TCP socket.
  """
  @spec down(t) :: :ok
  def down(sim) do
    sim
    |> lookup_child_process!(WebServer)
    |> ThousandIsland.stop()
  end

  @doc """
  Reopen the simulator's TCP socket.
  """
  @spec up(t) :: :ok
  def up(sim) do
    port_cache = lookup_child_process!(sim, PortCache)
    state_server = lookup_child_process!(sim, StateServer)

    case Supervisor.start_child(
           sim,
           {WebServer, port_cache: port_cache, state_server: state_server}
         ) do
      {:ok, _web_server} -> :ok
      {:error, :already_present} -> Supervisor.restart_child(sim, WebServer)
    end

    :ok
  end

  @doc """
  Gets the base_url for this instance.
  """
  @spec base_url(t) :: String.t()
  def base_url(sim) do
    port =
      sim
      |> lookup_child_process!(PortCache)
      |> PortCache.get()

    "http://localhost:#{port}"
  end

  @doc """
  Causes the server to return internal server errors.
  """
  @spec trigger_internal_server_errors(t, [selector_opt]) :: :ok
  def trigger_internal_server_errors(sim, opts \\ []) do
    sim
    |> lookup_child_process!(StateServer)
    |> StateServer.stub_response(selector_from_opts!(opts), :internal_server_error)
  end

  @doc """
  Causes the server to return invalid responses.
  """
  @spec trigger_invalid_responses(t, [selector_opt]) :: :ok
  def trigger_invalid_responses(sim, opts \\ []) do
    sim
    |> lookup_child_process!(StateServer)
    |> StateServer.stub_response(selector_from_opts!(opts), :invalid_response)
  end

  @doc """
  Removes stubbed responses from the server.
  """
  @spec clear_stubbed_responses(t, [selector_opt]) :: :ok
  def clear_stubbed_responses(sim, opts \\ []) do
    sim
    |> lookup_child_process!(StateServer)
    |> StateServer.clear_stubbed_responses(selector_from_opts!(opts))
  end

  defp selector_from_opts!(opts) do
    opts = Keyword.validate!(opts, [:operation, :bucket, :key])

    validate_operation!(opts[:operation])
    validate_binary_opt!(opts, :bucket)
    validate_binary_opt!(opts, :key)

    Map.new(opts)
  end

  defp validate_operation!(nil), do: :ok

  defp validate_operation!(operation) when operation in @operations, do: :ok

  defp validate_operation!(operation) do
    raise ArgumentError, "unsupported S3 operation selector: #{inspect(operation)}"
  end

  defp validate_binary_opt!(opts, key) do
    case opts[key] do
      nil -> :ok
      value when is_binary(value) -> :ok
      value -> raise ArgumentError, "#{key} selector must be a string, got: #{inspect(value)}"
    end
  end

  defp lookup_child_process!(sup, id) do
    {^id, pid, _, _} =
      sup
      |> Supervisor.which_children()
      |> List.keyfind!(id, 0)

    pid
  end
end
