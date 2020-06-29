ExUnit.configure(formatters: [ExUnit.CLIFormatter, ExUnitNotifier])

# Get Mix output sent to the current
# process to avoid polluting tests.
Mix.shell(Mix.Shell.Process)

ExUnit.start()
