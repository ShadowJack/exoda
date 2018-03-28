defmodule Exoda.Query.Select do
  @moduledoc """
  Helpers to build a $select parameter for OData query expression
  """
  
  @doc """
  Update `query_string_params` collection with $select parameter
  """
  @spec add_select(Map.t, Ecto.Query.t) :: Map.t
  def add_select(query_string_params, %Ecto.Query{select: %Ecto.Query.SelectExpr{expr: {:&, _, _}}}) do
    # select full entity
    query_string_params
  end
  def add_select(query_string_params, %Ecto.Query{select: %Ecto.Query.SelectExpr{fields: fields}}) do
    # select only some fields
    select = fields
    |> Enum.map(fn {{:., _, [_, field]}, _, _} -> field end)
    |> Enum.join(",")
    Map.put(query_string_params, "$select", select)
  end
end
