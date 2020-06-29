defmodule PhxDiff.TestSupport.FileHelpers do
  @moduledoc false

  import ExUnit.Assertions

  def assert_file(file) do
    assert File.regular?(file), "Expected #{file} to exist, but does not"
  end

  def refute_file(file) do
    refute File.regular?(file), "Expected #{file} to not exist, but it does"
  end

  def assert_file(file, match) do
    cond do
      is_list(match) ->
        assert_file(file, &Enum.each(match, fn m -> assert &1 =~ m end))

      is_binary(match) or Regex.regex?(match) ->
        assert_file(file, &assert(&1 =~ match))

      is_function(match, 1) ->
        assert_file(file)
        match.(File.read!(file))

      true ->
        raise inspect({file, match})
    end
  end

  def tmp_path do
    Path.expand("../../tmp/test/", __DIR__)
  end

  defp random_string(len) do
    len |> :crypto.strong_rand_bytes() |> Base.encode64() |> binary_part(0, len)
  end

  def with_tmp(function) do
    path = Path.join([tmp_path(), random_string(10)])

    try do
      File.rm_rf!(path)
      File.mkdir_p!(path)
      function.(path)
    after
      File.rm_rf!(path)
    end
  end
end
