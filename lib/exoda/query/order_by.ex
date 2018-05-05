defmodule Exoda.Query.OrderBy do
  alias Ecto.Query
  alias Ecto.Query.QueryExpr
  require Logger

  @moduledoc """
  Helpers to build $orderby parameters for OData query expression
  """

  
  @typep sources :: {}

  @doc """
  Add an $orderby parameter to the query string
  """
  @spec add_order_by(%{}, Query.t) :: %{}
  def add_order_by(query_string_params, %Query{order_bys: order_bys, sources: sources}) do
    case build_order_by_param(order_bys, sources) do
      "" -> query_string_params
      param -> Map.put(query_string_params, "$orderby", param)
    end
  end
  def add_order_by(query_string_params, _) do
    query_string_params
  end

  @doc """
  Build a parameter string from the list of Ecto query order_by expressions
  """
  @spec build_order_by_param([QueryExpr.t], sources) :: String.t
  def build_order_by_param(order_bys, sources) do
    order_bys
    |> Enum.flat_map(fn %QueryExpr{expr: kw} -> 
      Enum.map(kw, fn {order, {{:., _, [{:&, _, [idx]}, field]}, _, _}} -> 
        field_path = Exoda.Query.Field.get_path(sources, idx, field)
        "#{field_path} #{order}" 
      end)
    end)
    |> Enum.join(",")
  end
end
