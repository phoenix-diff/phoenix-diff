defmodule PhxDiffWeb.DiffSpecification do
  @moduledoc false

  alias PhxDiff.AppSpecification

  @type t :: %__MODULE__{
          source: AppSpecification.t(),
          target: AppSpecification.t()
        }

  defstruct [:source, :target]

  @spec new(AppSpecification.t(), AppSpecification.t()) :: t
  def new(%AppSpecification{} = source, %AppSpecification{} = target) do
    %__MODULE__{source: source, target: target}
  end
end
