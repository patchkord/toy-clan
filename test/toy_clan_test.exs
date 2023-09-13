defmodule ToyClanTest do
  use ExUnit.Case
  doctest ToyClan

  test "greets the world" do
    assert ToyClan.hello() == :world
  end
end
