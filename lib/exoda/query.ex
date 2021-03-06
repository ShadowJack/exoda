defmodule Exoda.Query do
  require Logger
  alias Ecto.Query

  @moduledoc """
  Module contains a part of implementation of `Ecto.Adapter` behaviour
  related to querying data.
  """

  @typep repo :: Ecto.Repo.t()
  @typep prepared :: Ecto.Adapter.prepared()
  @typep options :: Keyword.t()
  @typep query_meta :: Ecto.Adapter.query_meta()
  @typep query :: Ecto.Query.t()
  @typep process :: Ecto.Adapter.process()
  @typep cached :: Ecto.Adapter.cached()
  @typep operation :: :all | :update_all | :delete_all
  @typep params :: []

  @client Application.get_env(:exoda, :client)

  @doc """
  Commands invoked to prepare a query for `all`, `update_all` and `delete_all`.

  The returned result is given to `execute/6`.
  """
  @spec prepare(operation, query) ::
          {:cache, prepared} | {:nocache, prepared}
  def prepare(operation, query) do
    {:nocache, {operation, query}}
  end

  @doc """
  Executes a previously prepared query.

  It returns a tuple containing the number of entries and
  the result set as a list of lists. The result set may also be
  `nil` if a particular operation does not support them.

  The `meta` field is a map containing some of the fields found
  in the `Ecto.Query` struct.

  It receives a process function that should be invoked for each
  selected field in the query result in order to convert them to the
  expected Ecto type. The `process` function will be nil if no
  result set is expected from the query.
  """
  @spec execute(repo, query_meta, query, params, process | nil, options) :: result
            when result: {integer, [[term]] | nil} | no_return,
                 query:
                   {:nocache, prepared}
                   | {:cached, (prepared -> :ok), cached}
                   | {:cache, (cached -> :ok), prepared}
  def execute(_repo, query_meta, {:nocache, {operation, query}}, params, process, opts) do
    Logger.info(
      """
      Execute query.
      Query type: #{inspect(operation)}
      Query: #{inspect(query)}
      Query meta: #{inspect(query_meta)}
      Params: #{inspect(params)}
      Process: #{inspect(process)}
      Opts: #{inspect(opts)}
      Query sources: #{inspect(query.sources)}
      Query joins: #{inspect(query.joins)}
      Query select: #{inspect(query.select)}
      Query wheres: #{inspect(query.wheres)}
      Query order_bys: #{inspect(query.order_bys)}
      Query distinct: #{inspect(query.distinct)}
      Query limit: #{inspect(query.limit)}
      Query offset: #{inspect(query.offset)}
      """
    )

    with {:ok, url} <- build_url(operation, query, params),
         {:ok, headers} <- build_headers(operation),
         {:ok, response} <- @client.get(url, headers) do
      parse_response(response, process, query)
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @spec build_url(operation, query, params) :: {:ok, String.t} | {:error, String.t}
  defp build_url(:all, %Query{sources: sources} = query, params) do
    %{service_url: service_url} = Exoda.ServiceDescription.get_settings()
    {source_path, _schema} = elem(sources, 0)
    query_string = build_query_string(query, params)
    {:ok, "#{service_url}/#{source_path}#{query_string}"}
  end
  defp build_url(_, _, _), do: {:error, "Not supported"}

  # Builds a valid OData query string from Ecto query
  @spec build_query_string(query, params) :: String.t
  def build_query_string(query, params) do
    query_string = 
      Map.new()
      |> Exoda.Query.Unsupported.add_distinct(query)
      |> Exoda.Query.Unsupported.add_lock(query)
      |> Exoda.Query.Select.add_select(query)
      |> Exoda.Query.Filter.add_filter(query, params)
      |> Exoda.Query.OrderBy.add_order_by(query)
      |> Exoda.Query.Top.add_top(query)
      |> Exoda.Query.Skip.add_skip(query)
      |> Exoda.Query.Count.add_count(query)
      |> Enum.map(fn {name, value} -> "#{name}=#{value}" end)
      |> Enum.join("&")
      |> URI.encode()

    case query_string do
      "" -> ""
      q -> "?#{q}"
    end
  end



  @spec build_headers(operation) :: {:ok, HTTPoison.headers} | {:error, String.t}
  defp build_headers(:all) do
    {:ok, [{"Accept", "application/json"}]}
  end
  defp build_headers(_), do: {:error, "Not supported"}

  @spec parse_response(HTTPoison.Response.t, process | nil, query) :: {integer, [[term]] | nil}
  defp parse_response(_, nil, _) do
    Logger.warn("Empty process funciton is passed!")
    {0, []}
  end
  defp parse_response(%HTTPoison.Response{status_code: 200, body: body}, process, query) do
    case Jason.decode(body) do
      {:ok, %{"value" => items } = parsed_body} ->
        results = 
          items 
          |> Enum.map(fn item ->
            item 
            |> preprocess_response(query, parsed_body) 
            |> process.()
          end)

          {length(results), results}
      {:error, reason} ->
        Logger.error("Error fetching data from remote OData server: #{inspect(reason)}")
        {0, []}
    end
  end

  # order fields, extract values and add metadata if required
  @spec preprocess_response(Map.t, query, Map.t) :: List.t
  defp preprocess_response(item, %Query{select: select}, full_body) do
    item
    |> add_odata_type_value(select.fields)
    |> add_count_value(select.fields, Map.get(full_body, "@odata.count"))
    |> Map.to_list() 
    |> sort_fields(select.fields)
    |> Enum.map(fn {_, value} -> value end)
  end
  defp preprocess_response(item, _query, _), do: item

  @spec add_odata_type_value(Map.t, []) :: Map.t
  defp add_odata_type_value(item, fields) do
    has_odata_type = Enum.any?(fields, fn field ->
      case field do
        {{_, _, [_, "@odata.type"]}, _, _} -> true
        _ -> false
      end 
    end)

    if has_odata_type do
      Map.put_new(item, "@odata.type", "")
    else
      item
    end
  end

  @spec add_count_value(Map.t, [], String.t) :: Map.t
  defp add_count_value(item, fields, count_value) do
    has_count = Enum.any?(fields, fn field ->
      case field do
        {:count, _, _} -> true
        _ -> false
      end 
    end)

    if has_count do
      Map.put_new(item, "@odata.count", count_value)
    else
      item
    end
  end

  @spec sort_fields([any], []) :: [any]
  defp sort_fields(values, fields) do
    Enum.map(fields, fn 
      {{_, _, [_, field_source]}, _, _} -> 
        Enum.find(values, {field_source, nil}, fn {name, _} -> name == field_source end)
      {:count, _, _} -> 
        Enum.find(values, {"@odata.count", nil}, fn {name, _} -> name == "@odata.count" end)
    end)
  end
end
