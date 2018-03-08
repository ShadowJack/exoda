defmodule Exoda.Fakes.Client do
  alias HTTPoison.Response

  @behaviour Exoda.Client

  @impl true
  def get!(url, _ \\ [], _ \\ []) do
    {:ok, service_url} = 
      Application.get_env(:exoda, Exoda.Fakes.Repo) |> Keyword.fetch(:url)

    cond do
      url == service_url -> get_service_response()
      String.ends_with?(url, "$metadata") -> get_metadata_response()
      :otherwise -> not_found_response()
    end
  end

  @impl true
  def get(url, _ \\ [], _ \\ []) do
    cond do
      String.ends_with?(url, "Products") -> get_collection_response()
    end
  end

  @impl true
  def post(url, _ \\ "", headers \\ [], _ \\ []) do
    preference_header = get_preference_header(headers)
    cond do
      String.ends_with?(url, "Products") -> post_product_response(preference_header)
      :otherwise -> not_found_response()
    end
  end

  @impl true
  def patch(url, _ \\ "", headers \\ [], _ \\ []) do
    preference_header = get_preference_header(headers)
    patch_product_response(preference_header)
  end

  @impl true
  def delete(_url, _ \\ "", _headers \\ [], _ \\ []) do
    delete_product_response()
  end



  defp get_preference_header(headers) do
    headers |> Enum.find_value(fn {name, value} -> if name == "Preference", do: value, else: nil end)
  end

  # Get service information
  defp get_service_response() do
    %Response{
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
    %Response{
      status_code: 200,
      body: File.read!("test/stub_data/OData_metadata.xml"),
      headers: [
        {"Content-Type", "application/xml;charset=utf-8"},
        {"OData-Version", "4.0;"}
      ]
    }
  end

  # Get collection of products
  defp get_collection_response() do
    {:ok, 
      %Response{
        status_code: 200,
        body: File.read!("test/stub_data/products_collection.json"),
        headers: [
               {"Cache-Control", "no-cache"},
               {"Content-Length", "2011"},
               {"Content-Type", "application/json;odata.metadata=minimal;odata.streaming=true;IEEE754Compatible=false;charset=utf-8"},
               {"OData-Version", "4.0;"},
        ],
        request_url: "http://services.odata.org/V4/(S(1ldwlff3vlwnnll4udpfi4uj))/OData/OData.svc/Products",
      }
    }
  end

  defp not_found_response() do
    %Response{status_code: 404}   
  end

  # Create a new entity
  defp post_product_response("return=minimal") do
    {
      :ok,
      %Response{
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
      %Response{
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

  # Update existing entity
  defp patch_product_response("return=minimal") do
    {
      :ok,
      %Response{
        body: "",
        headers: [
          {"Location", "http://services.odata.org/V4/OData/(S(1ldwlff3vlwnnll4udpfi4uj))/OData.svc/Products(1)"},
          {"Preference-Applied", "return=minimal"},
          {"OData-Version", "4.0;"},
          {"OData-EntityId", "http://services.odata.org/V4/OData/(S(1ldwlff3vlwnnll4udpfi4uj))/OData.svc/Products(1)"}
        ],
        request_url: "http://services.odata.org/V4/OData/(S(1ldwlff3vlwnnll4udpfi4uj))/OData.svc/Products(1)",
        status_code: 204
      }
    }
  end
  defp patch_product_response(_) do
    {
      :ok,
      %Response{
           body: "{\"@odata.context\":\"http://services.odata.org/V4/OData/(S(1ldwlff3vlwnnll4udpfi4uj))/OData.svc/$metadata#Products/$entity\",\"ID\":1,\"Name\":\"Updated name\",\"Description\":\"Low fat milk\",\"ReleaseDate\":\"1995-10-01T00:00:00Z\",\"DiscontinuedDate\":null,\"Rating\":3,\"Price\":3.5}",
        headers: [
          {"Content-Type", "application/json;odata.metadata=minimal;odata.streaming=true;IEEE754Compatible=false;charset=utf-8"},
          {"Preference-Applied", "return=representation"},
          {"OData-Version", "4.0;"}
        ],
        request_url: "http://services.odata.org/V4/OData/(S(1ldwlff3vlwnnll4udpfi4uj))/OData.svc/Products(1)",
        status_code: 200
      }
    }
  end

  defp delete_product_response() do
    {
      :ok, 
      %HTTPoison.Response{
        body: "",
        headers: [
          {"OData-Version", "4.0;"},
        ],
        request_url: "http://services.odata.org/V4/OData/(S(1ldwlff3vlwnnll4udpfi4uj))/OData.svc/Products(0)",
        status_code: 204
      }
    }
  end
end
