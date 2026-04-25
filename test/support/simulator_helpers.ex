defmodule PhxDiff.SimulatorHelpers do
  @moduledoc """
  Helper functions for configuring the application to work with test simulators.
  """

  import ExUnit.Callbacks

  @doc """
  Configure the application to use the S3 simulator.
  """
  def configure_for_s3_simulator(_tags) do
    sim = start_supervised!(PhxDiff.S3Simulator)

    base_url = PhxDiff.S3Simulator.base_url(sim)
    Mox.stub(PhxDiff.Config.Mock, :s3_base_url, fn -> base_url end)

    [s3_simulator: sim]
  end
end
