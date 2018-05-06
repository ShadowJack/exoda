defmodule Exoda.Query.Top do
  alias Ecto.Query
  alias Ecto.Query.QueryExpr

  @moduledoc """
  Helper functions to build a $top OData expression
  """
  
  @doc """
  Adds a $top query parameter to parameters collection
  """
  @spec add_top(Map.t, Query.t) :: Map.t
  def add_top(query_params, %Query{limit: nil}), do: query_params
  def add_top(query_params, %Query{limit: %QueryExpr{expr: limit}}) do
    Map.put(query_params, "$top", limit)
  end

end
