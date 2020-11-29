# OpenTelemetryJaeger

`OpentelemetryJaeger` is a library for exporting [OpenTelemetry](https://opentelemetry.io/)
trace data, as modeled by [opentelemetry-erlang](https://github.com/open-telemetry/opentelemetry-erlang),
to a [Jaeger](https://www.jaegertracing.io/) endpoint.

The configuration is passed through the options specified when configuring the `:opentelemetry` application:

```elixir
config :opentelemetry,
  processors: [
    otel_batch_processor: %{
      exporter: {OpenTelemetryJaeger, %{
        host: "localhost",
        port: 6832,
        service_name: "MyService", # Defaults to `Mix.Project.config()[:app]`, in PascalCase.
        service_version: "MyServiceVersion" # Defaults to `Mix.Project.config()[:version]`.
      }}
    }
  ]
```

When the project is compiled, the [Jaeger Thrift IDL](https://github.com/jaegertracing/jaeger-idl/tree/master/thrift)
files, stored in the `priv` directory, are compiled and the output is stored in `lib/jaeger/thrift`.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `opentelemetry_jaeger` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:opentelemetry_jaeger, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/opentelemetry_jaeger](https://hexdocs.pm/opentelemetry_jaeger).

