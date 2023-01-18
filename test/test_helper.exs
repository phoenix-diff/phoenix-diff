ExUnit.configure(formatters: [ExUnit.CLIFormatter, ExUnitNotifier], capture_log: true)

# Get Mix output sent to the current
# process to avoid polluting tests.
Mix.shell(Mix.Shell.Process)

:otel_batch_processor.set_exporter(PhxDiff.TestSupport.OpenTelemetryTestExporter)

# Set up the mock config adapter
Mox.defmock(PhxDiff.Config.Mock, for: PhxDiff.Config.Adapter)
Application.put_env(:phx_diff, :config_adapter, PhxDiff.Config.Mock)

Mox.defmock(PhxDiffWeb.Config.Mock, for: PhxDiffWeb.Config.Adapter)
Application.put_env(:phx_diff, :web_config_adapter, PhxDiffWeb.Config.Mock)

ExUnit.start()
