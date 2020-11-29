defmodule OpentelemetryJaegerTest do
  use ExUnit.Case
  doctest OpentelemetryJaeger

  test "greets the world" do
    assert OpentelemetryJaeger.hello() == :world
  end
end
