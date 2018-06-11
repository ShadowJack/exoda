defmodule Exoda.Query.Count do
  alias Ecto.Query
  alias Ecto.Query.SelectExpr

  @moduledoc """
  Helper functions to build a $count OData expression
  """
  
  @doc """
  Adds a $count query parameter to parameters collection
  """
  @spec add_count(Map.t, Query.t) :: Map.t
  def add_count(query_params, %Query{select: %SelectExpr{fields: fields}}) do
    if count_is_requested(fields) do
      Map.put(query_params, "$count", "true")
    else
      query_params
    end
  end
  def add_count(query_params, _), do: query_params

  defp count_is_requested(fields) do
    (for {:count, _, [{{:., _, [{:&, _, [0]}, _]}, _, _}]} = f <- fields, do: f)
    |> Enum.any?()
  end
end
