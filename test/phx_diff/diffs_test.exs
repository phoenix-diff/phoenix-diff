defmodule PhxDiff.DiffsTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog
  import PhxDiff.TestSupport.FileHelpers
  import PhxDiff.TestSupport.OpenTelemetryTestExporter, only: [subscribe_to_otel_spans: 1]
  import PhxDiff.TestSupport.Sigils
  import PhxDiff.TestSupport.TelemetryHelpers, only: :macros

  alias PhxDiff.Diffs

  alias PhxDiff.Diffs.{
    AppSpecification,
    ComparisonError,
    Config
  }

  alias PhxDiff.TestSupport.TelemetryHelpers

  @unknown_phoenix_version ~V[0.0.99]

  describe "all_versions/1" do
    test "returns all versions" do
      versions = Diffs.all_versions()

      assert length(versions) > 25

      assert Enum.member?(versions, ~V[1.3.0])
      assert Enum.member?(versions, ~V[1.4.0-rc.2])
    end

    test "returns an empty list when no apps have been generated" do
      with_tmp(fn path ->
        config = build_config(path)

        assert [] = Diffs.all_versions(config: config)
      end)
    end
  end

  describe "release_versions/1" do
    test "returns all versions" do
      versions = Diffs.release_versions()

      assert length(versions) > 20

      assert Enum.member?(versions, ~V[1.3.0])
      refute Enum.member?(versions, ~V[1.4.0-rc.2])
    end

    test "returns an empty list when no apps have been generated" do
      with_tmp(fn path ->
        config = build_config(path)

        assert [] = Diffs.release_versions(config: config)
      end)
    end
  end

  describe "get_diff/3" do
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
      source = Diffs.default_app_specification(~V[1.3.1])
      target = Diffs.default_app_specification(~V[1.3.2])

      log_output =
        capture_log(fn ->
          {:ok, diff} = Diffs.get_diff(source, target)

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
      source = Diffs.default_app_specification(~V[1.3.1])
      target = Diffs.default_app_specification(~V[1.3.1])

      {:ok, diff} = Diffs.get_diff(source, target)

      assert diff == ""
    end

    test "returns an error when the source is an unknown version" do
      source = Diffs.default_app_specification(@unknown_phoenix_version)
      target = Diffs.default_app_specification(~V[1.3.1])

      {log_output, result} =
        capture_log_with_result(fn ->
          Diffs.get_diff(source, target)
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
      source = Diffs.default_app_specification(~V[1.3.1])
      target = Diffs.default_app_specification(@unknown_phoenix_version)

      assert {:error, error} = Diffs.get_diff(source, target)
      assert %ComparisonError{errors: [{:target, :unknown_version}]} = error
    end
  end

  describe "generate_sample_app/2" do
    test "stores the newly generated sample app in config.app_repo_path" do
      with_tmp(fn path ->
        config = build_config(path)

        assert {:ok, storage_dir} =
                 ~V[1.5.3]
                 |> Diffs.default_app_specification()
                 |> Diffs.generate_sample_app(config: config)

        assert storage_dir == Path.join(config.app_repo_path, "1.5.3")

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

        assert [~V[1.5.3]] = Diffs.all_versions(config: config)

        assert_temp_dirs_cleaned_up(config)
      end)
    end

    test "returns {:error, :unknown_version} when phoenix does not have the given version number" do
      with_tmp(fn path ->
        config = build_config(path)

        assert {:error, :unknown_version} =
                 Diffs.default_app_specification(~V[0.1.10])
                 |> Diffs.generate_sample_app(config: config)

        assert_temp_dirs_cleaned_up(config)
      end)
    end
  end

  describe "default_app_specification/1" do
    test "returns an app spec with no arguments for versions less than 1.5.0" do
      assert Diffs.default_app_specification(~V[1.4.16]) ==
               %AppSpecification{
                 phoenix_version: ~V[1.4.16],
                 phx_new_arguments: []
               }
    end

    test "returns an app spec with --live argument for versions >= 1.5.0" do
      for version <- [~V[1.5.0-rc.0], ~V[1.5.0], ~V[1.5.1]] do
        assert Diffs.default_app_specification(version) ==
                 %AppSpecification{
                   phoenix_version: version,
                   phx_new_arguments: ["--live"]
                 }
      end
    end
  end

  defp build_config(tmp_path) do
    %Config{
      app_repo_path: Path.join(tmp_path, "app_repo"),
      app_generator_workspace_path: Path.join(tmp_path, "generator_workspace")
    }
  end

  defp assert_temp_dirs_cleaned_up(config) do
    mix_archives_tmp_path =
      Path.join([
        config.app_generator_workspace_path,
        "mix_archives",
        "tmp"
      ])

    assert_dir_empty(mix_archives_tmp_path)

    generated_apps_path =
      Path.join([
        config.app_generator_workspace_path,
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
