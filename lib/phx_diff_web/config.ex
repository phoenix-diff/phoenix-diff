defmodule PhxDiffWeb.Config do
  @moduledoc false

  @doc """
  Render analytics scripts in layout template.

  Defaults to `false`.
  """
  @spec render_tracking_scripts?() :: boolean
  def render_tracking_scripts? do
    Application.get_env(:phx_diff, :render_tracking_scripts, false)
  end
end
