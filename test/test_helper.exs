ExUnit.configure(formatters: [ExUnit.CLIFormatter, ExUnitNotifier], capture_log: true)

# Get Mix output sent to the current
# process to avoid polluting tests.
Mix.shell(Mix.Shell.Process)

:otel_batch_processor.set_exporter(PhxDiff.TestSupport.OpenTelemetryTestExporter)

ExUnit.start()
