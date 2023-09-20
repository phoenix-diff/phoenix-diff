defmodule PhxDiffWeb.Params do
  @moduledoc false

  alias PhxDiff.AppSpecification
  alias PhxDiffWeb.DiffSpecification

  @spec decode_app_spec(String.t()) :: {:ok, AppSpecification.t()} | :error
  def decode_app_spec(slug) when is_binary(slug) do
    with [version_part | rest] <- String.split(slug),
         {:ok, version} <- Version.parse(version_part) do
      {:ok, AppSpecification.new(version, rest)}
    else
      _ -> :error
    end
  end

  @spec encode_app_spec(AppSpecification.t()) :: String.t()
  def encode_app_spec(%AppSpecification{} = app_spec) do
    Enum.join([to_string(app_spec.phoenix_version) | app_spec.phx_new_arguments], " ")
  end

  @spec encode_diff_spec(DiffSpecification.t()) :: String.t()
  def encode_diff_spec(%DiffSpecification{source: source, target: target}) do
    "#{encode_app_spec(source)}...#{encode_app_spec(target)}"
  end

  @spec decode_diff_spec(String.t()) :: {:ok, DiffSpecification.t()} | :error
  def decode_diff_spec(slug) when is_binary(slug) do
    with [source_slug, target_slug] <- String.split(slug, "...", parts: 2),
         {:ok, source_app_spec} <- decode_app_spec(source_slug),
         {:ok, target_app_spec} <- decode_app_spec(target_slug) do
      {:ok, DiffSpecification.new(source_app_spec, target_app_spec)}
    else
      _ -> :error
    end
  end
end

defimpl Phoenix.Param, for: PhxDiffWeb.DiffSpecification do
  def to_param(diff_spec), do: PhxDiffWeb.Params.encode_diff_spec(diff_spec)
end
