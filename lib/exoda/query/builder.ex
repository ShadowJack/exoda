defmodule Exoda.Query.Builder do
  require Logger

  @moduledoc """
  This module contains funcitons that build valid OData query
  from Ecto query
  """

  @typep params :: [any]
  @typep sources :: {{String.t, atom}}

  @doc """
  Builds a valid OData query string from Ecto query
  """
  @spec build_query_string(Ecto.Query.t, params) :: String.t
  def build_query_string(query, params) do
    query_string = 
      Map.new()
      |> add_select_option(query)
      |> add_filter_option(query, params)
      |> Enum.map(fn {name, value} -> "#{name}=#{value}" end)
      |> Enum.join("&")
      |> URI.encode()

    case query_string do
      "" -> ""
      q -> "?#{q}"
    end
  end


  @spec add_select_option(Map.t, Ecto.Query.t) :: Map.t
  # select full entity
  defp add_select_option(query_string, %Ecto.Query{select: %Ecto.Query.SelectExpr{expr: {:&, _, _}}}) do
    query_string
  end
  # select only some fields
  defp add_select_option(query_string, %Ecto.Query{select: %Ecto.Query.SelectExpr{fields: fields}}) do
    select = fields
    |> Enum.map(fn {{:., _, [_, field]}, _, _} -> field end)
    |> Enum.join(",")
    Map.put(query_string, "$select", select)
  end


  @spec add_filter_option(Map.t, Ecto.Query.t, params) :: Map.t
  # don't filter at all
  defp add_filter_option(query_string, %Ecto.Query{wheres: []}, _) do
    query_string
  end
  defp add_filter_option(query_string, %Ecto.Query{wheres: wheres, sources: sources}, params) do
    Logger.info("Query wheres: #{inspect(wheres)}")
    filter = do_add_filter_option(wheres, sources, params, "")
    Map.put(query_string, "$filter", filter)
  end

  @spec do_add_filter_option([Ecto.Query.QueryExpr.t], sources, params, String.t) :: String.t
  defp do_add_filter_option([], _, _, acc), do: acc
  defp do_add_filter_option([%{expr: expr, op: op} | tail], sources, params, acc) do
    new_filter = build_filter(expr, sources, params)
    updated_query = 
      case acc do
        "" -> "(#{new_filter})"
        query -> "#{query} #{convert_op(op)} (#{new_filter})"
      end
    do_add_filter_option(tail, sources, params, updated_query)
  end
  
  @spec build_filter(any, sources, params) :: String.t
  # Unary expressions and functions
  defp build_filter({:is_nil, [], [expr]}, sources, params), do: "(#{build_filter(expr, sources, params)}) eq null"
  defp build_filter({:not, [], [expr]}, sources, params), do: "not (#{build_filter(expr, sources, params)})"
  defp build_filter({op, [], _}, _, _) when op in [:min, :max, :sum, :avg] do
    throw "min/1, max/1, sum/1 and avg/1 functions are not supported by Exoda adapter"
  end
  defp build_filter({op, [], _}, _, _) when op in [:datetime_add, :date_add, :from_now, :ago] do
    throw "Date/time functions: datetime_add/3, date_add/3, from_now/2 and ago/2 are not supported by Exoda adapter"
  end
  # Get value from params
  defp build_filter({:^, _, [index]}, _, params), do: Enum.at(params, index)
  # Get source field name
  defp build_filter({{:., [], [{:&, [], [0]}, field]}, _, []}, _, _), do: field
  defp build_filter({{:., [], [{:&, [], [idx]}, field]}, _, []}, sources, _), do: get_assoc_field(sources, idx, field)
  # Type casting is not supported
  defp build_filter(%Ecto.Query.Tagged{type: _}, _, _) do
    throw "Type casting is not supported for values. OData server can cast types only for expressions."
  end
  # in/2 operator is not supported
  defp build_filter({:in, _, _}, _, _) do
    throw "Inclusion operator in/2 is not supported by Exoda adapter"
  end
  # Boolean operators
  defp build_filter({op, _, [left, right]}, sources, params) when op in [:and, :or] do
    "(#{build_filter(left, sources, params)}) #{convert_op(op)} (#{build_filter(right, sources, params)})"
  end
  # Naive like/2 function: escaped % symbols are not supported
  defp build_filter({:like, _, [expr, value]}, sources, params) do
    source = build_filter(expr, sources, params)
    trimmed_value = String.trim(value, "%")
    cond do
      String.starts_with?(value, "%") and String.ends_with?(value, "%") ->
        "contains(#{source}, '#{trimmed_value}')"
      String.starts_with?(value, "%") ->
        "endswith(#{source}, '#{trimmed_value}')"
      String.ends_with?(value, "%") ->
        "startswith(#{source}, '#{trimmed_value}')"
      :otherwise ->
        build_filter({:==, [], [expr, value]}, sources, params)
    end
  end
  # Build fragment expression
  defp build_filter({:fragment, _, parts}, sources, params), do: build_fragment(parts, sources, params)
  # Other binary expressoins
  defp build_filter({op, _, [left, right]}, sources, params) do
    "#{build_filter(left, sources, params)} #{convert_op(op)} #{build_filter(right, sources, params)}"
  end
  # Leave raw literal value as is
  defp build_filter(string, _, _) when is_binary(string), do: "'#{string}'"
  defp build_filter(literal, _, _), do: literal

  # Build full path to the field that is stored in associated entry
  # Associated entries might be nested, ex.
  # ```
  # Advertisements?$filter=startswith(FeaturedProduct/ProductDetail/Details, 'Prod')
  # ```
  @spec get_assoc_field(sources, integer, String.t) :: String.t | none
  defp get_assoc_field(sources, idx, field) do
    {_, source_schema} = elem(sources, 0)
    {_, target_schema} = elem(sources, idx)
    case find_associations_path(source_schema, target_schema, [], []) do
      "" -> raise "Association path from #{source_schema} to #{target_schema} is not found"
      path -> "#{path}/#{field}"
    end
  end

  @spec find_associations_path(module, module, [module], [String.t]) :: String.t
  defp find_associations_path(source, target, _, path) when source == target do
    Enum.reverse(path) |> Enum.join("/")
  end
  defp find_associations_path(source, target, visited, path) do
   source.__schema__(:associations) 
   |> Enum.map(fn assoc_name -> source.__schema__(:association, assoc_name) end)
   |> Enum.filter(fn assoc -> is_tuple(assoc.queryable) end)
   |> Enum.reject(fn %{queryable: {_, schema}} -> Enum.any?(visited, &(&1 == schema)) end)
   |> Stream.map(fn %{queryable: {field, schema}} -> find_associations_path(schema, target, [source | visited], [field | path]) end)
   |> Stream.drop_while(fn result -> result == [] end)
   |> Enum.take(1)
  end

  @spec build_fragment(Keyword.t, sources, params) :: String.t
  defp build_fragment(parts, sources, params) do
    Enum.reduce(parts, "", fn 
      {:raw, str}, acc -> "#{acc}#{str}"
      {:expr, expr}, acc -> "#{acc}#{build_filter(expr, sources, params)}"
    end)
  end

  @doc """
  Convert Ecto operators and functions into OData
  """
  @spec convert_op(atom) :: String.t
  def convert_op(:==), do: "eq"
  def convert_op(:!=), do: "ne"
  def convert_op(:>), do: "gt"
  def convert_op(:>=), do: "ge"
  def convert_op(:<), do: "lt"
  def convert_op(:<=), do: "le"
  def convert_op(op), do: to_string(op)

  @doc """
  Convert Ecto type to Edm type
  """
  @spec convert_type(atom) :: String.t
  def convert_type(:id), do: "Edm.Int64"
  def convert_type(:binary_id), do: "Edm.String"
  def convert_type(:integer), do: "Edm.Int32"
  def convert_type(:float), do: "Edm.Double"
  def convert_type(:boolean), do: "Edm.Boolean"
  def convert_type(:string), do: "Edm.String"
  def convert_type(:binary), do: "Edm.Binary"
  def convert_type(:time), do: "Edm.Time"
  def convert_type(:naive_datetime), do: "Edm.DateTime"
  def convert_type(:utc_datetime), do: "Edm.DateTime"
  def convert_type(other_type), do: throw "Type `#{other_type}` is not supported by Exoda adapter"
end
