defmodule ExodaTest do
  use ExUnit.Case
  doctest Exoda

  test "greets the world" do
    assert Exoda.hello() == :world
  end
end
