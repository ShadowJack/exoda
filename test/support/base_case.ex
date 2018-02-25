defmodule Exoda.BaseCase do
  use ExUnit.CaseTemplate

  setup_all do
    Mox.set_mox_global()

    # Setup stubs for basic OData server endpoints
    {:ok, service_url} = Application.get_env(:exoda, Exoda.RepoMock) |> Keyword.fetch(:url)
    Mox.stub(Exoda.ClientMock, :get!, fn url, _, _ ->
      cond do
        url == service_url -> service_response()
        String.ends_with?(url, "$metadata") -> metadata_response()
        :otherwise -> not_found_response()
      end
    end)

    :ok
  end

  defp service_response() do
    %HTTPoison.Response{
      status_code: 200,
      body: File.read!("test/stub_data/OData.svc.json"),
      headers: [
        {"Content-Type",
         "application/json;odata.metadata=minimal;odata.streaming=true;charset=utf-8"},
        {"OData-Version", "4.0;"}
      ]
    }
  end

  defp metadata_response() do
    %HTTPoison.Response{
      status_code: 200,
      body: File.read!("test/stub_data/OData_metadata.xml"),
      headers: [
        {"Content-Type", "application/xml;charset=utf-8"},
        {"OData-Version", "4.0;"}
      ]
    }
  end

  defp not_found_response() do
    %HTTPoison.Response{status_code: 404}   
  end
end
