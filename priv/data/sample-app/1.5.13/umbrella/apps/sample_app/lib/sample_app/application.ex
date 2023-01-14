defmodule SampleApp.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      SampleApp.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: SampleApp.PubSub}
      # Start a worker by calling: SampleApp.Worker.start_link(arg)
      # {SampleApp.Worker, arg}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: SampleApp.Supervisor)
  end
end
