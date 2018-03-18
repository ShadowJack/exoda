defmodule Exoda.Query.Builder do
  require Logger

  @moduledoc """
  This module contains funcitons that build valid OData query
  from Ecto query
  """

  @doc """
  Builds a valid OData query string from Ecto query
  """
  @spec build_query_string(Ecto.Query.t) :: String.t
  def build_query_string(query) do
    query_string = 
      Map.new()
      |> add_select_option(query)
      |> add_filter_option(query)
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


  @spec add_filter_option(Map.t, Ecto.Query.t) :: Map.t
  # don't filter at all
  defp add_filter_option(query_string, %Ecto.Query{wheres: []}) do
    query_string
  end
  defp add_filter_option(query_string, %Ecto.Query{wheres: wheres}) do
    Logger.info("Query wheres: #{inspect(wheres)}")
    filter = do_add_filter_option(wheres, "")
    Map.put(query_string, "$filter", filter)
  end

  @spec do_add_filter_option([Ecto.Query.QueryExpr.t], String.t) :: String.t
  defp do_add_filter_option([], acc), do: acc
  defp do_add_filter_option([%{expr: expr, op: op} | tail], acc) do
    new_filter = build_filter(expr)
    updated_query = 
      case acc do
        "" -> "(#{new_filter})"
        query -> "#{query} #{convert_op(op)} (#{new_filter})"
      end
    do_add_filter_option(tail, updated_query)
  end
  
  @spec build_filter(any) :: String.t
  # Unary expressions and functions
  defp build_filter({:is_nil, [], [expr]}), do: "(#{build_filter(expr)}) eq null"
  defp build_filter({:not, [], [expr]}), do: "not (#{build_filter(expr)})"
  defp build_filter({op, [], _}) when op in [:min, :max, :sum, :avg] do
    throw "min/1, max/1, sum/1 and avg/1 functions are not supported by Exoda adapter"
  end
  # Get source field
  defp build_filter({{:., [], [{:&, [], [0]}, field]}, _, []}), do: field
  defp build_filter({:in, _, _}) do
    throw "Inclusion operator in/2 is not supported by Exoda adapter"
  end
  # Boolean operators
  defp build_filter({op, _, [left, right]}) when op in [:and, :or] do
    "(#{build_filter(left)}) #{convert_op(op)} (#{build_filter(right)})"
  end
  # Other binary expressoins
  defp build_filter({op, _, [left, right]}) do
    "#{build_filter(left)} #{convert_op(op)} #{build_filter(right)}"
  end
  # Leave raw literal value as is
  defp build_filter(string) when is_binary(string), do: "'#{string}'"
  defp build_filter(literal), do: literal

  # Convert Ecto operators and functions into OData
  @spec convert_op(atom) :: String.t
  defp convert_op(:==), do: "eq"
  defp convert_op(:!=), do: "ne"
  defp convert_op(:>), do: "gt"
  defp convert_op(:>=), do: "ge"
  defp convert_op(:<), do: "lt"
  defp convert_op(:<=), do: "le"
  defp convert_op(op), do: to_string(op)
end
