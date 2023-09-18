defmodule PhxDiffWeb.DiffSelections.DiffSelection.Fields.Version do
  @moduledoc false

  use Ecto.Type

  @impl true
  def type, do: :string

  @impl true
  def cast(string) when is_binary(string), do: Version.parse(string)
  def cast(_), do: :error

  @impl true
  def load(string) when is_binary(string), do: Version.parse(string)
  def load(_), do: :error

  @impl true
  def dump(%Version{} = version), do: to_string(version)
  def dump(_), do: :error
end
