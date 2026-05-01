defmodule PhxDiff.Diffs.AppRepo.AppSpecPath do
  @moduledoc false

  alias PhxDiff.AppSpecification

  @args_to_path_mappings [
    {[], "default"},
    {["--live"], "live"},
    {["--no-ecto"], "no-ecto"},
    {["--no-live"], "no-live"},
    {["--no-html"], "no-html"},
    {["--binary-id"], "binary-id"},
    {["--umbrella"], "umbrella"}
  ]

  @spec path(AppSpecification.t()) :: String.t()
  def path(%AppSpecification{} = app_spec) do
    Path.join(
      to_string(app_spec.phoenix_version),
      phx_new_arguments_to_path(app_spec.phx_new_arguments)
    )
  end

  @spec from_path(String.t()) :: AppSpecification.t()
  def from_path(path) do
    path
    |> Path.split()
    |> then(fn [serialized_version, serialized_arguments] ->
      %AppSpecification{
        phoenix_version: Version.parse!(serialized_version),
        phx_new_arguments: phx_new_arguments_from_path(serialized_arguments)
      }
    end)
  end

  for {args, path} <- @args_to_path_mappings do
    defp phx_new_arguments_to_path(unquote(args)), do: unquote(path)
  end

  for {args, path} <- @args_to_path_mappings do
    defp phx_new_arguments_from_path(unquote(path)), do: unquote(args)
  end
end
