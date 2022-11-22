defmodule PhxDiff.TestSupport.DiffFixtures do
  @moduledoc false

  alias PhxDiff.AppSpecification

  # This module manages known diff fixtures for our test suite.
  #
  # To add a new diff fixture, run the following commands
  #
  #     $ MIX_ENV=test iex -S mix
  #     Erlang/OTP 23 [erts-11.2.2.4] [source] [64-bit] [smp:8:8] [ds:8:8:10] [async-threads:1] [hipe]
  #
  #     Interactive Elixir (1.12.3) - press Ctrl+C to exit (type h() ENTER for help)
  #     iex(1)> import PhxDiff.TestSupport.Sigils
  #     iex(2)> PhxDiff.TestSupport.DiffFixtures.save_diff_fixture!(
  #     ...(2)>   PhxDiff.AppSpecification.new(~V|1.5.9|, ["--live"]),
  #     ...(2)>   PhxDiff.AppSpecification.new(~V|1.6.0|, [])
  #     ...(2)> )
  #     :ok
  #

  def known_diff_for!(%AppSpecification{} = app_spec_1, %AppSpecification{} = app_spec_2) do
    diff_path = file_path(app_spec_1, app_spec_2)

    case File.read(diff_path) do
      {:ok, diff} -> diff
      {:error, _reason} -> raise "unable to read diff at #{diff_path}"
    end
  end

  # NOTE: This function is only designed to be called from iEX
  def save_diff_fixture!(version_1, version_2)
      when is_binary(version_1) and is_binary(version_2) do
    app_spec_1 = PhxDiff.default_app_specification(Version.parse!(version_1))
    app_spec_2 = PhxDiff.default_app_specification(Version.parse!(version_2))

    save_diff_fixture!(app_spec_1, app_spec_2)
  end

  def save_diff_fixture!(%AppSpecification{} = app_spec_1, %AppSpecification{} = app_spec_2) do
    {:ok, diff} = PhxDiff.fetch_diff(app_spec_1, app_spec_2)

    file_path(app_spec_1, app_spec_2)
    |> File.write!(diff)
  end

  defp file_path(version_1, version_2) do
    Path.join([__DIR__, "diff_fixtures", diff_file_name(version_1, version_2)])
  end

  defp diff_file_name(%AppSpecification{} = app_spec_1, %AppSpecification{} = app_spec_2) do
    "#{app_spec_1.phoenix_version}-#{serialize_phx_new_args(app_spec_1.phx_new_arguments)}-#{app_spec_2.phoenix_version}-#{serialize_phx_new_args(app_spec_2.phx_new_arguments)}.diff"
  end

  defp serialize_phx_new_args([]), do: "default"
  defp serialize_phx_new_args(["--live"]), do: "live"
  defp serialize_phx_new_args(["--no-ecto"]), do: "no-ecto"
end
