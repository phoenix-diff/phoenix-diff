defmodule PhxDiff.TestSupport.DiffFixtures do
  @moduledoc false

  # This module manages known diff fixtures for our test suite.
  #
  # To add a new diff fixture, run the following commands
  #
  #     $ MIX_ENV=test iex -S mix
  #     Erlang/OTP 23 [erts-11.2.2.4] [source] [64-bit] [smp:8:8] [ds:8:8:10] [async-threads:1] [hipe]
  #
  #     Interactive Elixir (1.12.3) - press Ctrl+C to exit (type h() ENTER for help)
  #     iex(1)> PhxDiff.TestSupport.DiffFixtures.save_diff_fixture!("1.5.5", "1.5.6")
  #     :ok
  #

  def known_diff_for!(%Version{} = version_1, %Version{} = version_2) do
    diff_path = file_path(version_1, version_2)

    case File.read(diff_path) do
      {:ok, diff} -> diff
      {:error, _reason} -> raise "unable to read diff at #{diff_path}"
    end
  end

  # NOTE: This function is only designed to be called from iEX
  def save_diff_fixture!(version_1, version_2)
      when is_binary(version_1) and is_binary(version_2) do
    version_1 = Version.parse!(version_1)
    version_2 = Version.parse!(version_2)

    {:ok, diff} =
      PhxDiff.fetch_diff(
        PhxDiff.default_app_specification(version_1),
        PhxDiff.default_app_specification(version_2)
      )

    file_path(version_1, version_2)
    |> File.write!(diff)
  end

  defp file_path(version_1, version_2) do
    Path.join([__DIR__, "diff_fixtures", diff_file_name(version_1, version_2)])
  end

  defp diff_file_name(%Version{} = version_1, %Version{} = version_2) do
    "#{version_1}-#{version_2}.diff"
  end
end
