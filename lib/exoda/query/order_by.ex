defmodule Exoda.Query.OrderBy do
  alias Ecto.Query
  alias Ecto.Query.QueryExpr
  require Logger

  @moduledoc """
  Helpers to build $orderby parameters for OData query expression
  """

  

  @doc """
  Add an $orderby parameter to the query string
  """
  @spec add_order_by(%{}, Query.t) :: %{}
  def add_order_by(query_string_params, %Query{order_bys: order_bys}) do
    case build_order_by_param(order_bys) do
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
  @spec build_order_by_param([QueryExpr.t]) :: String.t
  def build_order_by_param(order_bys) do
    order_bys
    |> Enum.flat_map(fn %QueryExpr{expr: kw} -> 
      #TODO: select field from the source(probably from association)
      Enum.map(kw, fn {order, {{:., _, [{:&, _, [_idx]}, field]}, _, _}} -> "#{field} #{order}" end)
    end)
    |> Enum.join(",")
  end
end
