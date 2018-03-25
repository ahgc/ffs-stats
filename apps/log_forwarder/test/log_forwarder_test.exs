defmodule LogForwarderTest do
  use ExUnit.Case
  doctest LogForwarder

  test "greets the world" do
    assert LogForwarder.hello() == :world
  end
end
