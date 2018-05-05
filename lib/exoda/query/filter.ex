defmodule Exoda.Query.Filter do
  require Logger

  @moduledoc """
  This module contains funcitons that build $filter parameter for OData query
  """

  @typep params :: [any]
  @typep sources :: {{String.t, atom}}
  @type t :: %Exoda.Query.Filter{sources: sources, ecto_params: params}

  @aggregation_functions [:min, :max, :sum, :avg]
  @date_functions [:datetime_add, :date_add, :from_now, :ago]

  defstruct sources: nil, ecto_params: []

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


  @doc """
  Add $filter parameter to OData query params
  """
  @spec add_filter(Map.t, Ecto.Query.t, params) :: Map.t
  def add_filter(query_string_params, %Ecto.Query{wheres: []}, _) do
    # don't filter at all
    query_string_params
  end
  def add_filter(query_string_params, %Ecto.Query{wheres: wheres, sources: sources}, ecto_params) do
    Logger.info("Query wheres: #{inspect(wheres)}")
    context = %Exoda.Query.Filter{sources: sources, ecto_params: ecto_params}
    filter = do_add_filter(wheres, context, "")
    Map.put(query_string_params, "$filter", filter)
  end

  @spec do_add_filter([Ecto.Query.QueryExpr.t], context :: t, String.t) :: String.t
  defp do_add_filter([], _, acc), do: acc
  defp do_add_filter([%{expr: expr, op: op} | tail], context, acc) do
    new_filter_expr = build_filter_expr(expr, context)
    updated_query = 
      case acc do
        "" -> "(#{new_filter_expr})"
        query -> "#{query} #{convert_op(op)} (#{new_filter_expr})"
      end
    do_add_filter(tail, context, updated_query)
  end
  
  @spec build_filter_expr(any, context :: t) :: String.t
  # is_nil(expr) -> expr eq null
  defp build_filter_expr({:is_nil, [], [expr]}, context) do 
    "(#{build_filter_expr(expr, context)}) eq null"
  end

  # not(expr) -> not (expr)
  defp build_filter_expr({:not, [], [expr]}, context) do 
    "not (#{build_filter_expr(expr, context)})"
  end
  
  # Aggregation functions are not supported
  defp build_filter_expr({op, [], _}, _) when op in @aggregation_functions do
    throw "min/1, max/1, sum/1 and avg/1 functions are not supported by Exoda adapter"
  end

  # Datetime functions are not supported
  defp build_filter_expr({op, [], _}, _) when op in @date_functions do
    throw "Date/time functions: datetime_add/3, date_add/3, from_now/2 and ago/2 are not supported by Exoda adapter"
  end

  # Get value from Ecto query params
  defp build_filter_expr({:^, _, [index]}, context) do
    Enum.at(context.ecto_params, index)
  end

  # Get field from schema
  defp build_filter_expr({{:., [], [{:&, [], [idx]}, field_name]}, _, []}, context) do
    Exoda.Query.Field.get_path(context.sources, idx, field_name)
  end

  # Type casting is not supported
  defp build_filter_expr(%Ecto.Query.Tagged{type: _}, _) do
    throw "Type casting is not supported for values. OData server can cast types only for expressions."
  end

  # in/2 operator is not supported
  defp build_filter_expr({:in, _, _}, _) do
    throw "Inclusion operator in/2 is not supported by Exoda adapter"
  end

  # Boolean operators
  defp build_filter_expr({op, _, [left, right]}, context) when op in [:and, :or] do
    "(#{build_filter_expr(left, context)}) #{convert_op(op)} (#{build_filter_expr(right, context)})"
  end

  # Naive like/2 function: escaped % symbols are not supported
  # like(expr, '%Test%') -> contains(expr, 'Test')
  # like(expr, '%Test')  -> startswith(expr, 'Test')
  # like(expr, 'Test%')  -> endswith(expr, 'Test')
  # like(expr, 'Test')  -> expr eq 'Test'
  defp build_filter_expr({:like, _, [expr, value]}, context) do
    source = build_filter_expr(expr, context)
    trimmed_value = String.trim(value, "%")
    cond do
      String.starts_with?(value, "%") and String.ends_with?(value, "%") ->
        "contains(#{source}, '#{trimmed_value}')"
      String.starts_with?(value, "%") ->
        "endswith(#{source}, '#{trimmed_value}')"
      String.ends_with?(value, "%") ->
        "startswith(#{source}, '#{trimmed_value}')"
      :otherwise ->
        build_filter_expr({:==, [], [expr, value]}, context)
    end
  end

  # Build filter from fragment expression
  defp build_filter_expr({:fragment, _, parts}, context) do
    build_fragment(parts, context)
  end

  # Other binary expressoins, like comparison operators etc
  defp build_filter_expr({op, _, [left, right]}, context) do
    "#{build_filter_expr(left, context)} #{convert_op(op)} #{build_filter_expr(right, context)}"
  end

  # Leave raw literal value as is
  # 'String' -> 'String'
  # 12 -> 12
  defp build_filter_expr(string, _) when is_binary(string), do: "'#{string}'"
  defp build_filter_expr(literal, _), do: literal


  # Helper to build fragment expression
  @spec build_fragment(Keyword.t, context :: t) :: String.t
  defp build_fragment(parts, context) do
    Enum.reduce(parts, "", fn 
      {:raw, str}, acc -> "#{acc}#{str}"
      {:expr, expr}, acc -> "#{acc}#{build_filter_expr(expr, context)}"
    end)
  end
end
