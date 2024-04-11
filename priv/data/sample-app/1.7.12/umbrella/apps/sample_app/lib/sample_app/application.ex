defmodule SampleApp.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      SampleApp.Repo,
      {DNSCluster, query: Application.get_env(:sample_app, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: SampleApp.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: SampleApp.Finch}
      # Start a worker by calling: SampleApp.Worker.start_link(arg)
      # {SampleApp.Worker, arg}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: SampleApp.Supervisor)
  end
end
