defmodule PhxDiffWeb.Config.AdminDashboardCredential do
  @moduledoc false

  @type t :: %__MODULE__{
          username: String.t(),
          password: String.t()
        }

  @derive {Inspect, only: [:username]}
  defstruct [:username, :password]
end
