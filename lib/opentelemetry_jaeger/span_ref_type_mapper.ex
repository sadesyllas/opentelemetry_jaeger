defprotocol OpenTelemetryJaeger.SpanRefTypeMapper do
  @moduledoc """
  An implementor of this protocol is required to read a list of `:opentelemetry.attribute()`s and resolve a
  `Jaeger.Thrift.SpanRefType`, if applicable.
  """

  require Jaeger.Thrift.SpanRefType, as: SpanRefType

  @type span_ref_type :: unquote(SpanRefType.child_of()) | unquote(SpanRefType.follows_from())

  @doc """
  Resolves a `Jaeger.Thrift.SpanRefType` based on a list of `:opentelemetry.attribute()`s.
  """
  @spec resolve(struct(), :opentelemetry.attributes()) :: span_ref_type() | nil
  def resolve(_, attributes)
end

defimpl OpenTelemetryJaeger.SpanRefTypeMapper, for: Any do
  require Jaeger.Thrift.SpanRefType, as: SpanRefType

  alias OpenTelemetryJaeger.SpanRefTypeMapper

  @doc """
  See `OpenTelemetryJaeger.SpanRefTypeMapper.resolve/2`.
  """
  @spec resolve(struct(), :opentelemetry.attributes()) :: SpanRefTypeMapper.span_ref_type() | nil
  def resolve(_, _attributes), do: SpanRefType.child_of()
end
