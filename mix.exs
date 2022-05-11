defmodule PhxDiff.MixProject do
  use Mix.Project

  def project do
    [
      app: :phx_diff,
      version: "0.1.0",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      preferred_cli_env: [
        ci: :test
      ],
      releases: releases(),
      default_release: :phx_diff,
      dialyzer: dialyzer(System.get_env())
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {PhxDiff.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "1.6.8"},
      {:phoenix_pubsub, "~> 2.0"},
      {:phoenix_html, "~> 3.0"},
      {:phoenix_live_view, "~> 0.17.5"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_dashboard, "~> 0.6"},
      {:ecto, "~> 3.8.3"},
      {:phoenix_ecto, "~> 4.4"},
      {:gettext, "~> 0.18"},
      {:jason, "~> 1.2"},
      {:plug_cowboy, "~> 2.5"},
      {:logster, "~> 1.0"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:honeybadger, "~> 0.18.1"},
      # The following are dependencies are needed for OpenTelemetry
      {:tls_certificate_check, "~> 1.11"},
      {:opentelemetry_api, "~> 1.0.0"},
      {:opentelemetry, "~> 1.0.0"},
      {:opentelemetry_exporter, "~> 1.0.0"},
      {:opentelemetry_phoenix, "~> 1.0.0-rc.7"},
      {:opentelemetry_liveview, "~> 1.0.0-rc.3"},
      {:esbuild, "~> 0.4", runtime: Mix.env() == :dev},
      {:dart_sass, "~> 0.4", runtime: Mix.env() == :dev},
      {:credo, "~> 1.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:mix_test_watch, "~> 1.0", only: :dev, runtime: false},
      {:ex_unit_notifier, "~> 1.2", only: :test, runtime: false},
      {:floki, ">= 0.30.0", only: :test}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      ci: [
        "compile --warnings-as-errors --force",
        "format --check-formatted",
        "test --raise",
        "credo --strict --all",
        "dialyzer"
      ],
      setup: ["deps.get", "cmd --cd assets yarn install"],
      "assets.deploy": [
        "esbuild default --minify",
        "sass default --no-source-map --style=compressed",
        "phx.digest"
      ]
    ]
  end

  # Environment specific dialyzer config
  defp dialyzer(%{"CI" => "true"}) do
    [
      plt_core_path: ".dialyzer/core",
      plt_local_path: ".dialyzer/local"
    ] ++ dialyzer()
  end

  defp dialyzer(_), do: dialyzer()

  # Common dialyzer config
  defp dialyzer do
    [plt_add_apps: [:mix, :ex_unit]]
  end

  defp releases do
    [
      phx_diff: [include_executables_for: [:unix]],
      applications: [runtime_tools: :permanent]
    ]
  end
end
