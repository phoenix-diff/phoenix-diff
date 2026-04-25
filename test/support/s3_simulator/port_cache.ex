defmodule PhxDiff.S3Simulator.PortCache do
  @moduledoc false

  use Agent

  def start_link(_opts) do
    Agent.start_link(fn -> 0 end)
  end

  def put(server, port) do
    Agent.update(server, fn _ -> port end)
  end

  def get(server) do
    Agent.get(server, & &1)
  end
end
