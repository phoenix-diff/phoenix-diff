defmodule PhxDiff.MockedConfigCase do
  @moduledoc """
  Test case to use when the code being tested needs to access the config.any()

  This allows us to stub values on the `PhxDiff.Config` boundary using mox in an
  async compatible manner.
  """
  use ExUnit.CaseTemplate

  setup context do
    Mox.set_mox_from_context(context)

    Mox.stub_with(PhxDiff.Config.Mock, PhxDiff.Config.DefaultAdapter)

    :ok
  end
end
