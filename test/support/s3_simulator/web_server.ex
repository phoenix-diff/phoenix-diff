defmodule PhxDiff.S3Simulator.WebServer do
  @moduledoc false

  alias PhxDiff.S3Simulator.PortCache
  alias PhxDiff.S3Simulator.WebServer.Router

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :supervisor,
      restart: :transient
    }
  end

  def start_link(opts) do
    %{port_cache: port_cache, state_server: state_server} =
      opts |> Keyword.validate!([:port_cache, :state_server]) |> Map.new()

    port = PortCache.get(port_cache)

    with {:ok, bandit} <-
           Bandit.start_link(
             ip: :loopback,
             port: port,
             plug: {Router, state_server: state_server},
             startup_log: false,
             thousand_island_options: [shutdown_timeout: :brutal_kill]
           ) do
      {:ok, {_addr, port}} = ThousandIsland.listener_info(bandit)

      # This allows us to keep the port we start on around after it is stopped or crashes.
      PortCache.put(port_cache, port)

      {:ok, bandit}
    end
  end
end
