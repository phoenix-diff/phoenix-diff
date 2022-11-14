defmodule PhxDiff.Supervisor do
  @moduledoc false

  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      Supervisor.child_spec({Task, &PhxDiff.Logger.install/0}, id: :logger_install_task),
      Supervisor.child_spec({Task, &PhxDiff.OpenTelemetry.setup/0}, id: :otel_install_task)
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
