defmodule OpenTelemetryJaeger.MixProject do
  use Mix.Project

  def project() do
    [
      app: :opentelemetry_jaeger,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      compilers: [:thrift | Mix.compilers()],
      thrift: [files: Path.wildcard("priv/thrift/**/*.thrift")],
      dialyzer: [ignore_warnings: ".dialyzer_ignore.exs"],

      # Documentation
      name: "OpenTelemetryJaeger",
      source_url: "https://github.com/sadesyllas/opentelemetry_jaeger",
      homepage_url: "https://github.com/sadesyllas/opentelemetry_jaeger",
      docs: [
        main: "OpenTelemetryJaeger",
        logo: "OpenTelemetryJaeger.png",
        extras: ["README.md"],
        filter_prefix: "OpenTelemetryJaeger"
      ],

      # Package
      package: [
        name: "OpenTelemetryJaeger",
        description: "A library to export OpenTelemetry spans to Jaeger.",
        licences: ["MIT"],
        links: %{
          "GitHub" => "https://github.com/sadesyllas/opentelemetry_jaeger",
          "OpenTelemetry" => "https://opentelemetry.io",
          "OpenTelemetry/Erlang" => "https://github.com/open-telemetry/opentelemetry-erlang"
        }
      ]
    ]
  end

  def application(), do: [extra_applications: []]

  defp deps() do
    [
      {:opentelemetry, "~> 0.5.0"},
      {:opentelemetry_api, "~> 0.5.0"},
      {:thrift, github: "pinterest/elixir-thrift"},
      {:finch, "~> 0.5.2"},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false, optional: true},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false, optional: true},
      {:ex_doc, "~> 0.23", only: :dev, runtime: false, optional: false}
    ]
  end
end
