defmodule Exoda.Fakes.Client do
  @behaviour Exoda.Client

  @impl true
  def get!(url, _ \\ [], _ \\ []) do
    {:ok, service_url} = 
      Application.get_env(:exoda, Exoda.RepoMock) |> Keyword.fetch(:url)

    cond do
      url == service_url -> get_service_response()
      String.ends_with?(url, "$metadata") -> get_metadata_response()
      :otherwise -> not_found_response()
    end
  end

  @impl true
  def post(url, _ \\ "", headers \\ [], _ \\ []) do
    preference_header = headers |> Enum.find(fn {name, _value} -> name == "Preference" end)
    cond do
      String.ends_with?(url, "Products") -> post_product_response(preference_header)
      :otherwise -> not_found_response()
    end
  end



  # Get service information
  defp get_service_response() do
    %HTTPoison.Response{
      status_code: 200,
      body: File.read!("test/stub_data/OData.svc.json"),
      headers: [
        {"Content-Type", "application/json;odata.metadata=minimal;odata.streaming=true;charset=utf-8"},
        {"OData-Version", "4.0;"}
      ]
    }
  end

  # Get service metadata
  defp get_metadata_response() do
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

  # Create a new entity
  defp post_product_response("return=minimal") do
    {
      :ok,
      %HTTPoison.Response{
        body: "",
        headers: [
          {"Location", "http://services.odata.org/V4/OData/(S(1ldwlff3vlwnnll4udpfi4uj))/OData.svc/Products(1)"},
          {"Preference-Applied", "return=minimal"},
          {"OData-Version", "4.0;"},
          {"OData-EntityId", "http://services.odata.org/V4/OData/(S(1ldwlff3vlwnnll4udpfi4uj))/OData.svc/Products(1)"}
        ],
        request_url: "http://services.odata.org/V4/(S(1ldwlff3vlwnnll4udpfi4uj))/OData/OData.svc/Products",
        status_code: 204
      }
    }
  end
  defp post_product_response(_) do
    {
      :ok,
      %HTTPoison.Response{
        body: "{\"@odata.context\":\"http://services.odata.org/V4/OData/(S(1ldwlff3vlwnnll4udpfi4uj))/OData.svc/$metadata#Products/$entity\",\"ID\":1,\"Name\":\"some name\",\"Description\":\"some description\",\"ReleaseDate\":\"2010-04-17T13:05:50.555Z\",\"DiscontinuedDate\":\"2010-04-17T10:20:30.4Z\",\"Rating\":42,\"Price\":120.5}",
        headers: [
          {"Content-Type", "application/json;odata.metadata=minimal;odata.streaming=true;IEEE754Compatible=false;charset=utf-8"},
          {"Location", "http://services.odata.org/V4/OData/(S(1ldwlff3vlwnnll4udpfi4uj))/OData.svc/Products(1)"},
          {"Preference-Applied", "return=representation"},
          {"OData-Version", "4.0;"}
        ],
        request_url: "http://services.odata.org/V4/(S(1ldwlff3vlwnnll4udpfi4uj))/OData/OData.svc/Products",
        status_code: 201
      }
    }
  end
end
