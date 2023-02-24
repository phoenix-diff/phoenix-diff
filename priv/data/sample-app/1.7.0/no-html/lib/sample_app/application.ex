defmodule SampleApp.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      SampleAppWeb.Telemetry,
      # Start the Ecto repository
      SampleApp.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: SampleApp.PubSub},
      # Start Finch
      {Finch, name: SampleApp.Finch},
      # Start the Endpoint (http/https)
      SampleAppWeb.Endpoint
      # Start a worker by calling: SampleApp.Worker.start_link(arg)
      # {SampleApp.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SampleApp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SampleAppWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
