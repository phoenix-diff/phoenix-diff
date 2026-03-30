defmodule PhxDiff.Diffs.AppRepoTest do
  use ExUnit.Case, async: true
  use PhxDiff.MockedConfigCase

  import PhxDiff.TestSupport.Sigils

  alias PhxDiff.AppSpecification
  alias PhxDiff.Diffs.AppRepo

  @valid_spec %AppSpecification{phoenix_version: ~V[1.7.1], phx_new_arguments: []}

  describe "read_raw_app_file/2" do
    test "returns raw bytes for a text file" do
      assert {:ok, content} = AppRepo.read_raw_app_file(@valid_spec, "mix.exs")
      assert content =~ "defmodule"
    end

    test "returns raw bytes for a binary file" do
      assert {:ok, content} = AppRepo.read_raw_app_file(@valid_spec, "priv/static/favicon.ico")
      assert is_binary(content)
    end

    test "rejects path traversal attempts" do
      assert {:error, :not_found} =
               AppRepo.read_raw_app_file(@valid_spec, "../../../etc/passwd")
    end

    test "returns error for nonexistent file" do
      assert {:error, :not_found} = AppRepo.read_raw_app_file(@valid_spec, "no_such_file.ex")
    end

    test "returns error for invalid version" do
      invalid_spec = %AppSpecification{phoenix_version: ~V[0.0.0], phx_new_arguments: []}
      assert {:error, :invalid_version} = AppRepo.read_raw_app_file(invalid_spec, "mix.exs")
    end
  end

  describe "read_app_file/2 path traversal" do
    test "rejects path with .. segments" do
      assert {:error, :not_found} = AppRepo.read_app_file(@valid_spec, "../../../etc/passwd")
    end

    test "rejects path with . segments" do
      assert {:error, :not_found} = AppRepo.read_app_file(@valid_spec, "./mix.exs")
    end

    test "rejects path with embedded .. segments" do
      assert {:error, :not_found} =
               AppRepo.read_app_file(@valid_spec, "lib/../../../etc/passwd")
    end

    test "rejects empty path" do
      assert {:error, :not_found} = AppRepo.read_app_file(@valid_spec, "")
    end
  end
end
