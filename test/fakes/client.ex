defmodule Exoda.Fakes.Client do
  require Logger
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
    Logger.info("Url requested: #{url}")
    cond do
      String.ends_with?(url, "select=Name") -> get_collection_select_name_response()
      String.ends_with?(url, "select=Name,Price") -> get_collection_select_name_price_response()
      String.ends_with?(url, "Products") -> get_collection_response()
      String.ends_with?(url, "filter=(Price%20gt%2020.0)") -> get_collection_filter_gt()
      String.ends_with?(url, "filter=(Price%20ge%2020.9)") -> get_collection_filter_ge()
      String.ends_with?(url, "filter=(Price%20lt%2020.0)") -> get_collection_filter_lt()
      String.ends_with?(url, "filter=(Price%20le%2020.9)") -> get_collection_filter_le()
      String.ends_with?(url, "filter=(Price%20eq%202.5)") -> get_collection_filter_eq()
      String.ends_with?(url, "filter=(Price%20ne%202.5)") -> get_collection_filter_ne()
      String.ends_with?(url, "filter=((Price%20gt%203.0)%20and%20(Name%20eq%20'Milk'))%20and%20(Rating%20le%204)") -> get_collection_filter_several_conditions()
      String.ends_with?(url, "filter=(not%20(Name%20eq%20'Milk'))") -> get_collection_filter_not()
      String.ends_with?(url, "filter=((DiscontinuedDate)%20eq%20null)") -> get_collection_filter_is_nil()
      String.ends_with?(url, "filter=(endswith(Name,%20'soda'))") -> get_collection_filter_like_ends()
      String.ends_with?(url, "filter=(startswith(Name,%20'Fruit%20'))") -> get_collection_filter_like_starts()
      String.ends_with?(url, "filter=(contains(Name,%20'monad'))") -> get_collection_filter_like_contains()
      String.ends_with?(url, "filter=(Name%20eq%20'Milk')") -> get_collection_filter_like_equals()
      String.ends_with?(url, "filter=((Name%20eq%20Milk)%20and%20(Price%20ge%201.0))") -> get_collection_filter_params()
      String.ends_with?(url, "filter=(Rating%20ge%204)") -> get_collection_filter_dynamic_fields()
      String.ends_with?(url, "filter=(tolower(Name)%20eq%20'milk')") -> get_collection_filter_fragment()
      String.ends_with?(url, "filter=(contains(ProductDetail/Details,%20'product'))") -> get_collection_filter_join()

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
        body: File.read!("test/stub_data/products/all.json"),
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

  # Get collection of products, select only one field
  defp get_collection_select_name_response() do
    {:ok,
      %HTTPoison.Response{
        body: File.read!("test/stub_data/products/select_name.json"),
        headers: [
          {"Content-Type", "application/json;odata.metadata=minimal;odata.streaming=true;IEEE754Compatible=false;charset=utf-8"},
          {"OData-Version", "4.0;"}
        ],
        request_url: "http://services.odata.org/V4/(S(1ldwlff3vlwnnll4udpfi4uj))/OData/OData.svc/Products?$select=Name",
        status_code: 200
      }}
  end

  # Get collection of products, select only two fields
  defp get_collection_select_name_price_response() do
    {:ok,
      %HTTPoison.Response{
        body: File.read!("test/stub_data/products/select_name_price.json"),
        headers: [ ],
        status_code: 200
      }}
  end

  # Get collection of products: filter by price
  defp get_collection_filter_gt() do
    {:ok,
      %HTTPoison.Response{
        body: File.read!("test/stub_data/products/filter_gt.json"),
        headers: [ ],
        status_code: 200
      }
    }
  end

  defp get_collection_filter_ge() do
    {:ok,
      %HTTPoison.Response{
        body: File.read!("test/stub_data/products/filter_ge.json"),
        headers: [ ],
        status_code: 200
      }
    }
  end

  defp get_collection_filter_lt() do
    {:ok,
      %HTTPoison.Response{
        body: File.read!("test/stub_data/products/filter_lt.json"),
        headers: [ ],
        status_code: 200
      }
    }
  end

  defp get_collection_filter_le() do
    {:ok,
      %HTTPoison.Response{
        body: File.read!("test/stub_data/products/filter_le.json"),
        headers: [ ],
        status_code: 200
      }
    }
  end

  defp get_collection_filter_eq() do
    {:ok,
      %HTTPoison.Response{
        body: File.read!("test/stub_data/products/filter_eq.json"),
        headers: [ ],
        status_code: 200
      }
    }
  end

  defp get_collection_filter_ne() do
    {:ok,
      %HTTPoison.Response{
        body: File.read!("test/stub_data/products/filter_ne.json"),
        headers: [ ],
        status_code: 200
      }
    }
  end

  defp get_collection_filter_not() do
    {:ok,
      %HTTPoison.Response{
        body: File.read!("test/stub_data/products/filter_not.json"),
        headers: [ ],
        status_code: 200
      }
    }
  end

  defp get_collection_filter_is_nil() do
    {:ok,
      %HTTPoison.Response{
        body: File.read!("test/stub_data/products/filter_is_nil.json"),
        headers: [ ],
        status_code: 200
      }
    }
  end

  defp get_collection_filter_like_ends() do
    {:ok,
      %HTTPoison.Response{
        body: File.read!("test/stub_data/products/filter_like_ends.json"),
        headers: [ ],
        status_code: 200
      }
    }
  end

  defp get_collection_filter_like_starts() do
    {:ok,
      %HTTPoison.Response{
        body: File.read!("test/stub_data/products/filter_like_starts.json"),
        headers: [ ],
        status_code: 200
      }
    }
  end

  defp get_collection_filter_like_contains() do
    {:ok,
      %HTTPoison.Response{
        body: File.read!("test/stub_data/products/filter_like_contains.json"),
        headers: [ ],
        status_code: 200
      }
    }
  end

  defp get_collection_filter_like_equals() do
    {:ok,
      %HTTPoison.Response{
        body: File.read!("test/stub_data/products/filter_like_equals.json"),
        headers: [ ],
        status_code: 200
      }
    }
  end
  J

  defp get_collection_filter_params() do
    {:ok,
      %HTTPoison.Response{
        body: File.read!("test/stub_data/products/filter_params.json"),
        headers: [ ],
        status_code: 200
      }
    }
  end

  defp get_collection_filter_dynamic_fields() do
    {:ok,
      %HTTPoison.Response{
        body: File.read!("test/stub_data/products/filter_dynamic_fields.json"),
        headers: [ ],
        status_code: 200
      }
    }
  end

  defp get_collection_filter_fragment() do
    {:ok,
      %HTTPoison.Response{
        body: File.read!("test/stub_data/products/filter_fragment.json"),
        headers: [ ],
        status_code: 200
      }
    }
  end

  # Get collection of products: filter by price, name and rating
  defp get_collection_filter_several_conditions() do
    {:ok,
      %HTTPoison.Response{
        body: File.read!("test/stub_data/products/filter_several_conditions.json"),
        headers: [],
        status_code: 200
      }}
  end

  # Get collection of products: filter by associated ProductDetail
  defp get_collection_filter_join() do
    {:ok,
      %HTTPoison.Response{
        body: File.read!("test/stub_data/products/filter_join.json"),
        headers: [],
        status_code: 200
      }}
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
