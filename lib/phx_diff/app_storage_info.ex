defmodule PhxDiff.AppStorageInfo do
  @moduledoc """
  Information about where a generated sample application was stored.
  """

  defstruct [:app_path, :post_store_instructions]

  @type t :: %__MODULE__{
          app_path: String.t(),
          post_store_instructions: String.t() | nil
        }

  @doc false
  @spec new(String.t(), String.t() | nil) :: t
  def new(app_path, post_store_instructions) do
    %__MODULE__{app_path: app_path, post_store_instructions: post_store_instructions}
  end
end
