defmodule PhxDiffWeb.ServerSideCompareLive do
  @moduledoc false
  use PhxDiffWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <h1>Server Side Compare</h1>
    """
  end
end
