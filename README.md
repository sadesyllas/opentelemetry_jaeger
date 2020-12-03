# OpenTelemetryJaeger

`OpenTelemetryJaeger` is a library for exporting [OpenTelemetry](https://opentelemetry.io/)
trace data, as modeled by [opentelemetry-erlang](https://github.com/open-telemetry/opentelemetry-erlang),
to a [Jaeger](https://www.jaegertracing.io/) endpoint.

The configuration is passed through the options specified when configuring the `:opentelemetry` application:

```elixir
config :opentelemetry,
  processors: [
    otel_batch_processor: %{
      exporter: {OpenTelemetryJaeger, %{
        # Defaults to `:agent`.
        endpoint_type: :agent,

        # Defaults to `"localhost"`.
        host: "localhost",

        # Defaults to `6832`.
        port: 6832,

        # Used only when `endpoint_type` is set to `:collector`.
        http_headers: [{"X-Foo", "Bar"}],

        # Defaults to `OpenTelemetryJaeger.SpanRefTypeMapperDefault` and if set, the module must implement the
        # `OpenTelemetryJaeger.SpanRefTypeMapper` protocol. It is used when using linking spans together and the
        # implementation for `Any` returns `SpanRefType.child_of()`.
        span_ref_type_mapper: MySpanRefTypeMapper,

        # https://hexdocs.pm/finch/Finch.html#start_link/1
        finch_settings: [],

        # Defaults to `Mix.Project.config()[:app]`, in PascalCase.
        service_name: "MyService",

        # Defaults to `Mix.Project.config()[:version]`.
        service_version: "MyServiceVersion"
      }}
    }
  ]
```

When the project is compiled, the [Jaeger Thrift IDL](https://github.com/jaegertracing/jaeger-idl/tree/master/thrift)
files, stored in the `priv` directory, are compiled and the output is stored in `lib/jaeger/thrift`.

For the meaning of the configuration key `span_ref_type_mapper`, see `OpenTelemetryJaeger.SpanRefTypeMapper`.

Internally, `OpenTelemetryJaeger` starts a `DynamicSupervisor` to supervise the connection processes started by `Finch`.

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

