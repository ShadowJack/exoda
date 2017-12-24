defmodule ExodaClientTest do
  use ExUnit.Case
  doctest ExodaClient

  test "greets the world" do
    assert ExodaClient.hello() == :world
  end
end
