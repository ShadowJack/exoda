defmodule ExodaClientTest do
  use ExUnit.Case, async: true
  alias Exoda.Client

  @service_url "http://services.odata.org/V4/Northwind/Northwind.svc/"
  
  test "init/1 raises when :url configuration is missing" do
    assert_raise ArgumentError, ~r":url is not configured", fn ->
      Client.init([])
    end
  end

  test "Client starts when valid :url configuration is provided" do
    {:ok, client} = Client.start_link([url: @service_url])
    assert Process.alive?(client)
  end
end
