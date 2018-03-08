defmodule ExodaClientTest do
  use ExUnit.Case, async: true
  alias Exoda.{ServiceDescription}

  @valid_opts [repo: Exoda.Fakes.Repo, otp_app: :exoda]

  test "service description process is successfully started" do
    assert {:ok, _} = ServiceDescription.start_link(@valid_opts)
  end

  test "initialization fails if configuration is incomplete" do
    assert_raise ArgumentError, ~r"Wrong configuration", fn ->
      ServiceDescription.init([])
    end

    assert_raise RuntimeError, ~r"Missing configuration", fn ->
      ServiceDescription.init(repo: :some_repo, otp_app: :exoda)
    end
  end

  test "settings are accessible after initialization" do
    {:ok, _} = ServiceDescription.start_link(@valid_opts)

    {:ok, service_url} = Application.get_env(:exoda, Exoda.Fakes.Repo) |> Keyword.fetch(:url)

    assert %{service_url: ^service_url, namespace: "ODataDemo"} =
             ServiceDescription.get_settings()
  end
end
