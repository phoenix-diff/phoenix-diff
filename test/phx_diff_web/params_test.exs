defmodule PhxDiffWeb.ParamsTest do
  use ExUnit.Case, async: true

  import PhxDiff.TestSupport.Sigils

  alias PhxDiff.AppSpecification
  alias PhxDiffWeb.DiffSpecification
  alias PhxDiffWeb.Params

  describe "app specs" do
    test "encoding an app spec with no params" do
      app_spec = AppSpecification.new(~V|1.5.0|, [])
      assert Params.encode_app_spec(app_spec) == "1.5.0"
    end

    test "encoding an app spec with one param" do
      app_spec = AppSpecification.new(~V|1.5.0|, ["--live"])
      assert Params.encode_app_spec(app_spec) == "1.5.0 --live"
    end

    test "encoding an app spec with multiple param" do
      app_spec = AppSpecification.new(~V|1.5.0|, ["--live", "--no-ecto"])
      assert Params.encode_app_spec(app_spec) == "1.5.0 --live --no-ecto"
    end

    test "decoding an app spec with no params" do
      assert {:ok, %AppSpecification{phoenix_version: ~V|1.5.0|, phx_new_arguments: []}} =
               Params.decode_app_spec("1.5.0")
    end

    test "decoding an app spec with one param" do
      assert {:ok, %AppSpecification{phoenix_version: ~V|1.5.0|, phx_new_arguments: ["--live"]}} =
               Params.decode_app_spec("1.5.0 --live")
    end

    test "decoding an app spec with multiple params" do
      assert {:ok,
              %AppSpecification{
                phoenix_version: ~V|1.5.0|,
                phx_new_arguments: ["--live", "--no-ecto"]
              }} = Params.decode_app_spec("1.5.0 --live --no-ecto")
    end

    test "decoding an invalid version" do
      assert :error = Params.decode_app_spec("foo")
    end

    test "decoding an empty string" do
      assert :error = Params.decode_app_spec("")
    end
  end

  describe "diff spec" do
    test "encoding a diff spec" do
      diff_spec =
        DiffSpecification.new(
          AppSpecification.new(~V|1.5.0|, ["--live", "--no-ecto"]),
          AppSpecification.new(~V|1.5.1|, ["--live"])
        )

      assert Params.encode_diff_spec(diff_spec) == "1.5.0 --live --no-ecto...1.5.1 --live"
    end

    test "decoding a diff spec" do
      source = AppSpecification.new(~V|1.5.0|, ["--live", "--no-ecto"])
      target = AppSpecification.new(~V|1.5.1|, ["--live"])

      assert {:ok, %DiffSpecification{source: ^source, target: ^target}} =
               Params.decode_diff_spec("1.5.0 --live --no-ecto...1.5.1 --live")
    end
  end
end
