defmodule ExodaClientTest do
  use ExUnit.Case, async: true
  alias Exoda.ServiceDescription

  @valid_opts [repo: Exoda.TestRepo, otp_app: :exoda, ]
  
  test "init/1 raises configuration is incomplete" do
    assert_raise ArgumentError, ~r":url is not configured", fn ->
      ServiceDescription.init([])
    end
  end

  test "service description is successfully started" do
    assert_raise ArgumentError, ~r":url is not configured", fn ->
      ServiceDescription.init([])
    end
  end
end
