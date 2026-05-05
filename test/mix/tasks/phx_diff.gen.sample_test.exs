defmodule Mix.Tasks.PhxDiff.Gen.SampleTest do
  use PhxDiff.MockedConfigCase, async: true

  import Mox

  alias ExAws.S3, as: ExAwsS3
  alias Mix.Tasks.PhxDiff.Gen
  alias PhxDiff.AppSpecification
  alias PhxDiff.Config.Mock
  alias PhxDiff.Diffs.AppRepo.Store.FileSystem
  alias PhxDiff.Diffs.AppRepo.Store.S3
  alias PhxDiff.TestSupport.DiffFixtures

  @diffs_to_compare [
    {{"1.4.16", []}, {"1.4.17", []}},
    {{"1.5.2", ["--live"]}, {"1.5.3", ["--live"]}},
    {{"1.5.9", []}, {"1.5.9", ["--live"]}},
    {{"1.6.0-rc.1", []}, {"1.6.0", []}}
  ]

  describe "filesystem app repo store adapter" do
    setup do
      stub(Mock, :app_repo_store, fn -> FileSystem end)

      :ok
    end

    test "outputs the appropriate git instructions after generating an app" do
      Gen.Sample.run(["1.5.2", "--live"])

      assert_receive {:mix_shell, :info, [msg]}

      assert msg == """

             Successfully generated sample app.

             To add this to version control, run:

                 git add priv/data/sample-app/1.5.2/live
                 git add -f priv/data/sample-app/1.5.2/live/config/prod.secret.exs
             """
    end

    for {{version_1, v1_opts}, {version_2, v2_opts}} <- @diffs_to_compare do
      test "returns known diff comparing #{version_1} #{Enum.join(v1_opts, " ")} to #{version_2} #{Enum.join(v2_opts, " ")}" do
        v1_app_spec = app_spec(unquote(version_1), unquote(v1_opts))
        v2_app_spec = app_spec(unquote(version_2), unquote(v2_opts))

        Gen.Sample.run([unquote(version_1)] ++ unquote(v1_opts))
        Gen.Sample.run([unquote(version_2)] ++ unquote(v2_opts))

        assert {:ok, diff} = PhxDiff.fetch_diff(v1_app_spec, v2_app_spec)

        assert diff == DiffFixtures.known_diff_for!(v1_app_spec, v2_app_spec)
      end
    end
  end

  describe "S3 app repo store adapter" do
    @describetag :tmp_dir

    setup [{PhxDiff.SimulatorHelpers, :configure_for_s3_simulator}]

    setup %{aws_config: aws_config, tmp_dir: tmp_dir} do
      bucket = unique_bucket_name()

      Mock
      |> stub(:app_repo_store, fn -> S3 end)
      |> stub(:app_repo_s3_store_bucket, fn -> bucket end)
      |> stub(:app_repo_s3_store_cache_path, fn -> Path.join(tmp_dir, "app_repo_s3_store_cache") end)
      |> stub(:app_generator_workspace_path, fn -> Path.join(tmp_dir, "generator_workspace") end)

      assert {:ok, _response} = bucket |> ExAwsS3.put_bucket("us-east-1") |> request(aws_config)

      [bucket: bucket]
    end

    test "uploads a tarball for the generated app", %{aws_config: aws_config, bucket: bucket} do
      key = "1.5.2/live.tar.gz"

      Gen.Sample.run(["1.5.2", "--live"])

      assert {:ok, %{body: <<31, 139, _rest::binary>>}} =
               bucket |> ExAwsS3.get_object(key) |> request(aws_config)
    end

    test "outputs no post-store instructions after generating an app" do
      Gen.Sample.run(["1.5.2", "--live"])

      assert_receive {:mix_shell, :info, [msg]}

      assert msg == """

             Successfully generated sample app.
             """
    end

    for {{version_1, v1_opts}, {version_2, v2_opts}} <- @diffs_to_compare do
      test "returns known diff comparing #{version_1} #{Enum.join(v1_opts, " ")} to #{version_2} #{Enum.join(v2_opts, " ")}" do
        v1_app_spec = app_spec(unquote(version_1), unquote(v1_opts))
        v2_app_spec = app_spec(unquote(version_2), unquote(v2_opts))

        Gen.Sample.run([unquote(version_1)] ++ unquote(v1_opts))
        Gen.Sample.run([unquote(version_2)] ++ unquote(v2_opts))

        assert {:ok, diff} = PhxDiff.fetch_diff(v1_app_spec, v2_app_spec)

        assert diff == DiffFixtures.known_diff_for!(v1_app_spec, v2_app_spec)
      end
    end
  end

  test "errors with an invalid version id" do
    Gen.Sample.run(["not_a_version"])

    assert_receive {:mix_shell, :error, [msg]}

    assert msg == ~s|Invalid version: \"not_a_version\"|
  end

  test "errors with an unknown version" do
    Gen.Sample.run(["0.1.10"])

    assert_receive {:mix_shell, :error, [msg]}

    assert msg =~ ~s|Unknown version: "0.1.10"|
  end

  test "errors when a phoenix version isn't specified" do
    Gen.Sample.run([])

    assert_receive {:mix_shell, :error, [msg]}

    assert msg == "A phoenix version must be specified"
  end

  defp app_spec(version, opts) do
    AppSpecification.new(Version.parse!(version), opts)
  end

  defp request(operation, aws_config) do
    ExAws.request(operation, aws_config)
  end

  defp unique_bucket_name do
    "test-bucket-#{System.unique_integer([:positive])}"
  end
end
