defmodule BlinkyTest do
  use ExUnit.Case
  doctest Blinky

  test "greets the world" do
    assert Blinky.hello() == :world
  end
end
