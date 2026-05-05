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
    credential = PhxDiff.S3Simulator.generate_credential(sim)

    base_url = PhxDiff.S3Simulator.base_url(sim)

    PhxDiff.Config.Mock
    |> Mox.stub(:s3_base_url, fn -> base_url end)
    |> Mox.stub(:s3_access_key_id, fn -> credential.access_key_id end)
    |> Mox.stub(:s3_secret_access_key, fn -> credential.secret_access_token end)
    |> Mox.stub(:s3_region, fn -> "us-east-1" end)

    aws_config = build_aws_config(sim, credential)

    [s3_simulator: sim, aws_config: aws_config]
  end

  defp build_aws_config(sim, credential) do
    uri = URI.parse(PhxDiff.S3Simulator.base_url(sim))

    [
      access_key_id: credential.access_key_id,
      secret_access_key: credential.secret_access_token,
      region: "us-east-1",
      scheme: "#{uri.scheme}://",
      host: uri.host,
      port: uri.port,
      normalize_path: false,
      retries: [
        max_attempts: 1,
        max_attempts_client: 1
      ]
    ]
  end
end
