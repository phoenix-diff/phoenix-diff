defmodule PhxDiffWeb.ServerSideCompareLive do
  @moduledoc false
  use PhxDiffWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"diff_specification" => diff_specification}, _uri, socket) do
    with {:ok, diff_specification} <- PhxDiffWeb.Params.decode_diff_spec(diff_specification) do
      # This jumps it to 1.1 mb of memory by itself
      PhxDiff.fetch_diff(diff_specification.source, diff_specification.target)
    end

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <h1>Server Side Compare</h1>
    """
  end
end
