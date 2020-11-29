defmodule OpenTelemetryJaeger do
  @moduledoc """
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
  """

  require Jaeger.Thrift.TagType, as: TagType

  @keys [:host, :port, :service_name, :service_version]
  @enforce_keys @keys
  defstruct @keys

  @type t :: %__MODULE__{
          host: charlist(),
          port: pos_integer(),
          service_name: binary(),
          service_version: binary()
        }

  alias Jaeger.Thrift.{Agent, Batch, Log, Process, Span, Tag}
  alias Thrift.Protocol.Binary

  @doc """
  Initializes the exporter's configuration by constructing a `t:OpenTelemetryJaeger.t/0`.
  """
  @spec init(map()) :: {:ok, t()}
  def init(opts) when is_map(opts) do
    host =
      opts
      |> Map.get(:host, "localhost")
      |> to_charlist()

    port = Map.get(opts, :port, 6832)

    service_name =
      Map.get_lazy(opts, :service_name, fn ->
        Mix.Project.config()
        |> Keyword.get(:app)
        |> to_string()
        |> Macro.camelize()
      end)

    service_version =
      Map.get_lazy(opts, :service_version, fn ->
        Mix.Project.config()[:version]
      end)

    opts = %__MODULE__{
      host: host,
      port: port,
      service_name: service_name,
      service_version: service_version
    }

    {:ok, opts}
  end

  @doc """
  Transforms a batch of `t:OpenTelemetry.span_ctx/0`s into a batch of `Jaeger.Thrift.Span`s.

  Then, it sends the batch to the specified Jaeger endpoint.
  """
  @spec export(atom() | :ets.tid(), :otel_resource.t(), term()) :: :ok
  def export(ets_table, resource, opts) do
    _ = :otel_resource.attributes(resource)

    :ets.foldl(
      fn span, acc ->
        [span | acc]
      end,
      [],
      ets_table
    )
    |> prepare_payload(opts)
    |> send_payload(opts)

    :ok
  end

  @doc """
  Shuts down an `OpenTelemetryJaeger` exporter.
  """
  @spec shutdown(term()) :: :ok
  def shutdown(_), do: :ok

  @spec prepare_payload([tuple()], t()) :: binary
  defp prepare_payload(spans, opts) do
    batch = %{
      Agent.EmitBatchArgs.new()
      | batch: prepare_batch(spans, opts)
    }

    batch
    |> Agent.EmitBatchArgs.serialize()
    |> IO.iodata_to_binary()
  end

  @spec prepare_batch([tuple()], t()) :: map()
  defp prepare_batch(spans, opts) do
    process = %{
      Process.new()
      | service_name: opts.service_name,
        tags: [
          %Tag{
            Tag.new()
            | key: "client.version",
              v_str: opts.service_version,
              v_type: 0
          }
        ]
    }

    %{
      Batch.new()
      | process: process,
        spans: to_jaeger_spans(spans)
    }
  end

  @spec send_payload(binary(), t()) :: :ok
  defp send_payload(data, %__MODULE__{host: host, port: port}) do
    {:ok, server} = :gen_udp.open(0)

    message =
      Binary.serialize(
        :message_begin,
        {
          :oneway,
          :os.system_time(:microsecond),
          "emitBatch"
        }
      )

    :ok = :gen_udp.send(server, host, port, [message | data])

    :gen_udp.close(server)

    :ok
  end

  @spec to_jaeger_spans([tuple()]) :: [Span.t()]
  defp to_jaeger_spans(spans), do: Enum.map(spans, &to_jaeger_span/1)

  @spec to_jaeger_span({
          :span,
          :opentelemetry.trace_id() | :undefined,
          :opentelemetry.span_id() | :undefined,
          :opentelemetry.tracestate() | :undefined,
          :opentelemetry.span_id() | :undefined,
          binary() | atom(),
          :opentelemetry.span_kind() | :undefined,
          :opentelemetry.timestamp(),
          :opentelemetry.timestamp() | :undefined,
          :opentelemetry.attributes() | :undefined,
          :opentelemetry.events(),
          :opentelemetry.links(),
          :opentelemetry.status() | :undefined,
          integer() | :undefined,
          boolean() | :undefined,
          tuple() | :undefined
        }) :: Span.t()
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defp to_jaeger_span(
         {:span, trace_id, span_id, state, parent_span_id, name, kind, start_time, end_time,
          attributes, events, links, status, flags, is_recording, instrumentation_library}
       )
       when ((is_integer(trace_id) and trace_id > 0) or trace_id == :undefined) and
              ((is_integer(span_id) and span_id > 0) or span_id == :undefined) and
              (is_list(state) or state == :undefined) and
              ((is_integer(parent_span_id) and parent_span_id > 0) or parent_span_id == :undefined) and
              (is_binary(name) or is_atom(name)) and is_atom(kind) and
              is_integer(start_time) and
              (is_integer(end_time) or end_time == :undefined) and
              (is_list(attributes) or attributes == :undefined) and
              is_list(events) and
              is_list(links) and
              (is_tuple(status) or status == :undefined) and
              (is_integer(flags) or flags == :undefined) and
              (is_boolean(is_recording) or is_recording == :undefined) and
              (is_tuple(instrumentation_library) or instrumentation_library == :undefined) do
    to_jaeger_span(
      name,
      trace_id,
      span_id,
      parent_span_id,
      flags,
      start_time,
      end_time,
      attributes,
      events
    )
  end

  @spec to_jaeger_span(
          binary() | atom(),
          pos_integer() | :undefined,
          pos_integer() | :undefined,
          pos_integer() | :undefined,
          integer() | :undefined,
          :opentelemetry.timestamp(),
          :opentelemetry.timestamp() | :undefined,
          :opentelemetry.attributes() | :undefined,
          :opentelemetry.events()
        ) :: Span.t()
  # credo:disable-for-next-line Credo.Check.Refactor.FunctionArity
  defp to_jaeger_span(
         name,
         trace_id,
         span_id,
         parent_span_id,
         flags,
         start_time,
         end_time,
         attributes,
         events
       ) do
    %Span{
      Span.new()
      | operation_name: to_string(name),
        trace_id_low: to_jaeger_span_id(trace_id),
        trace_id_high: 0,
        span_id: to_jaeger_span_id(span_id),
        parent_span_id: to_jaeger_span_id(parent_span_id),
        flags: to_jaeger_flags(flags),
        start_time: :opentelemetry.convert_timestamp(start_time, :microsecond),
        duration: to_duration(start_time, end_time),
        tags: to_jaeger_tags(attributes),
        logs: to_jaeger_logs(events)
    }
  end

  @spec to_jaeger_span_id(:opentelemetry.span_id() | :undefined) :: non_neg_integer()
  defp to_jaeger_span_id(id)
  defp to_jaeger_span_id(:undefined), do: 0
  defp to_jaeger_span_id(id) when is_integer(id) and id > 0, do: id

  @spec to_jaeger_flags(integer() | :undefined) :: non_neg_integer()
  defp to_jaeger_flags(flags)
  defp to_jaeger_flags(:undefined), do: 0
  defp to_jaeger_flags(flags) when is_integer(flags), do: flags

  @spec to_duration(:opentelemetry.timestamp(), :opentelemetry.timestamp() | :undefined) ::
          non_neg_integer()
  defp to_duration(start_time, end_time)
  defp to_duration(_start_time, :undefined), do: 0

  defp to_duration(start_time, end_time) when is_integer(start_time) and is_integer(end_time),
    do: :erlang.convert_time_unit(end_time - start_time, :native, :microsecond)

  @spec to_jaeger_tags(:opentelemetry.attributes()) :: [Tag.t()]
  defp to_jaeger_tags(attributes)
  defp to_jaeger_tags(:undefined), do: []

  defp to_jaeger_tags(attributes) do
    attributes
    |> to_jaeger_tags([])
    |> Enum.reverse()
  end

  @spec to_jaeger_tags(:opentelemetry.attributes(), [Tag.t()]) :: [Tag.t()]
  defp to_jaeger_tags(attributes, tags)
  defp to_jaeger_tags([], tags), do: tags

  defp to_jaeger_tags([{key, value} | attributes], tags),
    do: to_jaeger_tags(attributes, [to_jaeger_tag(key, value) | tags])

  @spec to_jaeger_tag(:opentelemetry.attribute_key(), :opentelemetry.attribute_value()) :: Tag.t()
  defp to_jaeger_tag(key, value)
  defp to_jaeger_tag(key, value) when is_function(value), do: to_jaeger_tag(key, value.())

  defp to_jaeger_tag(key, value) when is_list(value),
    do: to_jaeger_tag(key, IO.iodata_to_binary(value))

  defp to_jaeger_tag(key, value) when is_binary(key) or is_atom(key) do
    Tag.new()
    |> Map.merge(%{
      v_type: to_jaeger_tag_value_type(value),
      key: to_string(key)
    })
    |> Map.put(get_jaeger_tag_value_key_name(value), value)
  end

  @spec get_jaeger_tag_value_key_name(bitstring() | number() | boolean() | nil) ::
          :v_str | :v_double | :v_long | :v_bool | :v_binary
  defp get_jaeger_tag_value_key_name(value)

  defp get_jaeger_tag_value_key_name(value)
       when is_binary(value) or is_nil(value) or is_list(value),
       do: :v_str

  defp get_jaeger_tag_value_key_name(value) when is_float(value), do: :v_double
  defp get_jaeger_tag_value_key_name(value) when is_number(value), do: :v_long
  defp get_jaeger_tag_value_key_name(value) when is_boolean(value), do: :v_bool
  defp get_jaeger_tag_value_key_name(value) when is_bitstring(value), do: :v_binary

  @spec to_jaeger_tag_value_type(bitstring() | number() | boolean() | nil) :: 0 | 1 | 2 | 3 | 4
  defp to_jaeger_tag_value_type(nil), do: TagType.string()
  defp to_jaeger_tag_value_type(value) when is_binary(value), do: TagType.string()
  defp to_jaeger_tag_value_type(value) when is_float(value), do: TagType.double()
  defp to_jaeger_tag_value_type(value) when is_number(value), do: TagType.long()
  defp to_jaeger_tag_value_type(value) when is_boolean(value), do: TagType.bool()
  defp to_jaeger_tag_value_type(value) when is_bitstring(value), do: TagType.binary()

  @spec to_jaeger_logs(:opentelemetry.events()) :: [Log.t()]
  defp to_jaeger_logs(events)
  defp to_jaeger_logs(events), do: to_jaeger_logs(events, [])

  @spec to_jaeger_logs(:opentelemetry.events(), [Log.t()]) :: [Log.t()]
  defp to_jaeger_logs(events, logs)
  defp to_jaeger_logs([], logs), do: logs

  defp to_jaeger_logs([event | events], logs),
    do: to_jaeger_logs(events, [to_jaeger_log(event) | logs])

  @spec to_jaeger_log(:opentelemetry.event()) :: Log.t()
  defp to_jaeger_log(event)

  defp to_jaeger_log({:event, timestamp, key, attributes}) when is_binary(key) or is_atom(key) do
    attributes = [{"event.name", to_string(key)} | attributes]

    %Log{
      Log.new()
      | timestamp: :opentelemetry.convert_timestamp(timestamp, :microsecond),
        fields: to_jaeger_tags(attributes)
    }
  end

  # @spec to_span_kind(atom()) :: binary()
  # defp to_span_kind(kind)
  # defp to_span_kind(:undefined), do: "SPAN_KIND_UNSPECIFIED"
  # defp to_span_kind(:INTERNAL), do: "SPAN_KIND_UNSPECIFIED"
  # defp to_span_kind(:PRODUCER), do: "PRODUCER"
  # defp to_span_kind(:CONSUMER), do: "CONSUMER"
  # defp to_span_kind(:SERVER), do: "SERVER"
  # defp to_span_kind(:CLIENT), do: "CLIENT"
end
