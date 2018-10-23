ExUnit.start

Mix.Task.run "ecto.create", ~w(-r SampleApp.Repo --quiet)
Mix.Task.run "ecto.migrate", ~w(-r SampleApp.Repo --quiet)
Ecto.Adapters.SQL.begin_test_transaction(SampleApp.Repo)

