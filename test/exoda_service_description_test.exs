defmodule ExodaClientTest do
  use ExUnit.Case, async: true
  alias Exoda.{ServiceDescription, ClientMock}

  @valid_opts [repo: Exoda.RepoMock, otp_app: :exoda]

  setup do
    # Setup basic stubs
    {:ok, service_url} = Application.get_env(:exoda, Exoda.RepoMock) |> Keyword.fetch(:url)

    Mox.stub(ClientMock, :get!, fn url, _, _ ->
      cond do
        url == service_url ->
          %HTTPoison.Response{
            status_code: 200,
            body: File.read!("test/stub_data/OData.svc.json"),
            headers: [
              {"Content-Type",
               "application/json;odata.metadata=minimal;odata.streaming=true;IEEE754Compatible=false;charset=utf-8"},
              {"OData-Version", "4.0;"},
              {"Access-Control-Allow-Origin", "*"},
              {"Access-Control-Allow-Methods", "GET"},
              {"Access-Control-Allow-Headers",
               "Accept, Origin, Content-Type, MaxDataServiceVersion"},
              {"Access-Control-Expose-Headers", "DataServiceVersion"}
            ]
          }

        String.ends_with?(url, "$metadata") ->
          %HTTPoison.Response{
            status_code: 200,
            body: File.read!("test/stub_data/OData_metadata.xml"),
            headers: [
              {"Content-Length", "7147"},
              {"Content-Type", "application/xml;charset=utf-8"},
              {"X-Content-Type-Options", "nosniff"},
              {"OData-Version", "4.0;"},
              {"Access-Control-Allow-Origin", "*"},
              {"Access-Control-Allow-Methods", "GET"},
              {"Access-Control-Allow-Headers",
               "Accept, Origin, Content-Type, MaxDataServiceVersion"},
              {"Access-Control-Expose-Headers", "DataServiceVersion"}
            ]
          }

        :otherwise ->
          %HTTPoison.Response{status_code: 404}
      end
    end)

    Mox.set_mox_global()
  end

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

    {:ok, service_url} = Application.get_env(:exoda, Exoda.RepoMock) |> Keyword.fetch(:url)

    assert %{service_url: ^service_url, namespace: "ODataDemo"} =
             ServiceDescription.get_settings()
  end
end
