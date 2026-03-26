defmodule PhxDiff.Diffs.AppRepoTest do
  use ExUnit.Case, async: true

  import PhxDiff.TestSupport.Sigils

  alias PhxDiff.AppSpecification
  alias PhxDiff.Diffs.AppRepo

  @valid_spec %AppSpecification{phoenix_version: ~V[1.7.1], phx_new_arguments: []}

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
