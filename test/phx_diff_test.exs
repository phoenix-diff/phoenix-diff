defmodule PhxDiffTest do
  use PhxDiff.MockedConfigCase, async: false

  import ExUnit.CaptureLog
  import PhxDiff.TestSupport.FileHelpers
  import PhxDiff.TestSupport.OpenTelemetryTestExporter, only: [subscribe_to_otel_spans: 1]
  import PhxDiff.TestSupport.Sigils
  import PhxDiff.TestSupport.TelemetryHelpers, only: :macros
  import Mox

  alias PhxDiff.AppSpecification
  alias PhxDiff.ComparisonError

  alias PhxDiff.TestSupport.TelemetryHelpers

  @unknown_phoenix_version ~V[0.0.99]

  describe "all_versions/0" do
    test "returns all versions" do
      versions = PhxDiff.all_versions()

      assert length(versions) > 25

      assert Enum.member?(versions, ~V[1.3.0])
      assert Enum.member?(versions, ~V[1.4.0-rc.2])
    end

    @tag :tmp_dir
    test "returns an empty list when no apps have been generated", %{tmp_dir: tmp_dir} do
      stub_repo_paths(tmp_dir)

      assert [] = PhxDiff.all_versions()
    end
  end

  describe "release_versions/0" do
    test "returns all versions" do
      versions = PhxDiff.release_versions()

      assert length(versions) > 20

      assert Enum.member?(versions, ~V[1.3.0])
      refute Enum.member?(versions, ~V[1.4.0-rc.2])
    end

    @tag :tmp_dir
    test "returns an empty list when no apps have been generated", %{tmp_dir: tmp_dir} do
      stub_repo_paths(tmp_dir)

      assert [] = PhxDiff.release_versions()
    end
  end

  describe "fetch_diff/2" do
    @diff_start_event [:phx_diff, :diffs, :generate, :start]
    @diff_stop_event [:phx_diff, :diffs, :generate, :stop]
    @diff_exception_event [:phx_diff, :diffs, :generate, :exception]
    @diff_events [
      @diff_start_event,
      @diff_stop_event,
      @diff_exception_event
    ]

    setup [:subscribe_to_otel_spans]

    setup context do
      TelemetryHelpers.subscribe_to_telemetry_events(context, @diff_events)
      :ok
    end

    test "returns content when versions are valid" do
      source = PhxDiff.default_app_specification(~V[1.3.1])
      target = PhxDiff.default_app_specification(~V[1.3.2])

      log_output =
        capture_log(fn ->
          {:ok, diff} = PhxDiff.fetch_diff(source, target)

          assert diff =~ "config/config.exs config/config.exs"
        end)

      assert_received_telemetry_event(
        @diff_start_event,
        {_, %{source_spec: ^source, target_spec: ^target}}
      )

      assert_received_telemetry_event(
        @diff_stop_event,
        {_, %{source_spec: ^source, target_spec: ^target}}
      )

      refute_received_telemetry_event(@diff_exception_event, _)

      assert log_output =~ ~S|Comparing "1.3.1" to "1.3.2"|
      assert log_output =~ ~S|Generated in|

      assert_receive {:otel_span,
                      %{
                        name: :"PhxDiff.Diffs.get_diff/3",
                        attributes: %{
                          "diff.source_phoenix_version": "1.3.1",
                          "diff.target_phoenix_version": "1.3.2"
                        }
                      }}
    end

    test "returns empty when versions are the same" do
      source = PhxDiff.default_app_specification(~V[1.3.1])
      target = PhxDiff.default_app_specification(~V[1.3.1])

      {:ok, diff} = PhxDiff.fetch_diff(source, target)

      assert diff == ""
    end

    test "returns an error when the source is an unknown version" do
      source = PhxDiff.default_app_specification(@unknown_phoenix_version)
      target = PhxDiff.default_app_specification(~V[1.3.1])

      {log_output, result} =
        capture_log_with_result(fn ->
          PhxDiff.fetch_diff(source, target)
        end)

      assert {:error, error} = result
      assert %ComparisonError{errors: [{:source, :unknown_version}]} = error

      assert_received_telemetry_event(
        @diff_start_event,
        {_, %{source_spec: ^source, target_spec: ^target}}
      )

      assert_received_telemetry_event(
        @diff_stop_event,
        {_, %{source_spec: ^source, target_spec: ^target, error: ^error}}
      )

      refute_received_telemetry_event(@diff_exception_event, _)

      assert log_output =~ ~s|Comparing "#{@unknown_phoenix_version}" to "1.3.1"|
      assert log_output =~ ~S|Unable to generate diff|
    end

    test "returns an error when the target is an unknown version" do
      source = PhxDiff.default_app_specification(~V[1.3.1])
      target = PhxDiff.default_app_specification(@unknown_phoenix_version)

      assert {:error, error} = PhxDiff.fetch_diff(source, target)
      assert %ComparisonError{errors: [{:target, :unknown_version}]} = error
    end
  end

  describe "generate_sample_app/1" do
    @tag :tmp_dir
    test "stores the newly generated sample app in config.app_repo_path", %{tmp_dir: tmp_dir} do
      stub_repo_paths(tmp_dir)

      assert {:ok, storage_dir} =
               ~V[1.5.3]
               |> PhxDiff.default_app_specification()
               |> PhxDiff.generate_sample_app()

      assert storage_dir == PhxDiff.Config.app_repo_path() |> Path.join("1.5.3")

      assert_file(Path.join(storage_dir, "mix.exs"))

      assert_file(Path.join(storage_dir, "config/prod.secret.exs"), fn file ->
        assert file =~ ~s|secret_key_base: secret_key_base|
      end)

      assert_file(Path.join(storage_dir, "config/config.exs"), fn file ->
        assert file =~ ~s|secret_key_base: "aaaaaaaa"|
        assert file =~ ~s|signing_salt: "aaaaaaaa"|
      end)

      assert_file(Path.join(storage_dir, "lib/sample_app_web/endpoint.ex"), fn file ->
        assert file =~ ~s|signing_salt: "aaaaaaaa"|
      end)

      assert [~V[1.5.3]] = PhxDiff.all_versions()

      assert_temp_dirs_cleaned_up()
    end

    @tag :tmp_dir
    test "returns {:error, :unknown_version} when phoenix does not have the given version number",
         %{tmp_dir: tmp_dir} do
      stub_repo_paths(tmp_dir)

      assert {:error, :unknown_version} =
               PhxDiff.default_app_specification(~V[0.1.10])
               |> PhxDiff.generate_sample_app()

      assert_temp_dirs_cleaned_up()
    end
  end

  describe "default_app_specification/1" do
    test "returns an app spec with no arguments for versions less than 1.5.0" do
      assert PhxDiff.default_app_specification(~V[1.4.16]) ==
               %AppSpecification{
                 phoenix_version: ~V[1.4.16],
                 phx_new_arguments: []
               }
    end

    test "returns an app spec with --live argument for versions >= 1.5.0" do
      for version <- [~V[1.5.0-rc.0], ~V[1.5.0], ~V[1.5.1]] do
        assert PhxDiff.default_app_specification(version) ==
                 %AppSpecification{
                   phoenix_version: version,
                   phx_new_arguments: ["--live"]
                 }
      end
    end
  end

  defp stub_repo_paths(tmp_dir) do
    PhxDiff.Config.Mock
    |> stub(:app_repo_path, fn -> Path.join(tmp_dir, "app_repo") end)
    |> stub(:app_generator_workspace_path, fn -> Path.join(tmp_dir, "generator_workspace") end)
  end

  defp assert_temp_dirs_cleaned_up do
    app_generator_workspace_path = PhxDiff.Config.app_generator_workspace_path()

    mix_archives_tmp_path =
      Path.join([
        app_generator_workspace_path,
        "mix_archives",
        "tmp"
      ])

    assert_dir_empty(mix_archives_tmp_path)

    generated_apps_path =
      Path.join([
        app_generator_workspace_path,
        "generated_apps"
      ])

    assert_dir_empty(generated_apps_path)
  end

  defp assert_dir_empty(path) do
    case File.ls(path) do
      {:ok, []} ->
        :ok

      {:ok, contents} when is_list(contents) ->
        flunk("""
        expected #{path} to be empty, but had the following entities

        #{inspect(contents)}
        """)

      {:error, _} ->
        :ok
    end
  end

  defp capture_log_with_result(function) when is_function(function, 0) do
    test_pid = self()
    ref = make_ref()

    log_output =
      capture_log(fn ->
        result = function.()
        send(test_pid, {:log_result, ref, result})
      end)

    receive do
      {:log_result, ^ref, result} -> {log_output, result}
    end
  end
end
