defmodule PhxDiff.Diffs.ComparisonError do
  @moduledoc """
  Indicates there were error(s) compariong two app specs
  """

  alias PhxDiff.Diffs.AppSpecification

  @type field :: :source | :target
  @type error :: :unknown_version

  @type t :: %__MODULE__{
          source: AppSpecification.t(),
          target: AppSpecification.t(),
          errors: [{field, error}]
        }

  defexception [:source, :target, :errors]

  def exception(opts \\ []) do
    %AppSpecification{} = source = Keyword.fetch!(opts, :source)
    %AppSpecification{} = target = Keyword.fetch!(opts, :target)
    errors = Keyword.fetch!(opts, :errors)

    %__MODULE__{source: source, target: target, errors: errors}
  end

  def message(error) do
    """
    unable to compare app specifications

      #{pretty(error.errors)}

      Source:
    #{pretty(error.source)}

      Target:
    #{pretty(error.source)}
    """
  end

  defp pretty(term) do
    inspect(term, pretty: true)
    |> String.split("\n")
    |> Enum.map_join("\n", &("    " <> &1))
  end
end
