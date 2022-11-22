defmodule PhxDiffWeb.PageLive.DiffSelection.Fields.Variant do
  @moduledoc false

  use Ecto.Type

  @impl true
  def type, do: {:array, :string}

  @impl true
  def cast("default"), do: {:ok, []}
  def cast("live"), do: {:ok, ["--live"]}
  def cast(_), do: :error

  @impl true
  def load(_), do: :error

  @impl true
  def dump(_), do: :error
end
