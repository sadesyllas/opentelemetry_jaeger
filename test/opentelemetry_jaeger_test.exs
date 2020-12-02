defmodule OpenTelemetryJaegerTest do
  use ExUnit.Case
  doctest OpenTelemetryJaeger

  test "greets the world" do
    assert OpenTelemetryJaeger.hello() == :world
  end
end
