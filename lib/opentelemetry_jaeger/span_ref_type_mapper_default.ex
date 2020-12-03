defmodule OpenTelemetryJaeger.SpanRefTypeMapperDefault do
  @moduledoc """
  A default implementation for `OpenTelemetryJaeger.SpanRefTypeMapper`.
  """

  defstruct []

  defimpl OpenTelemetryJaeger.SpanRefTypeMapper do
    require Jaeger.Thrift.SpanRefType, as: SpanRefType

    alias OpenTelemetryJaeger.SpanRefTypeMapper

    @doc """
    See `OpenTelemetryJaeger.SpanRefTypeMapper.resolve/2`.
    """
    @spec resolve(struct(), :opentelemetry.attributes()) ::
            SpanRefTypeMapper.span_ref_type() | nil
    def resolve(_, _attributes), do: SpanRefType.child_of()
  end
end
