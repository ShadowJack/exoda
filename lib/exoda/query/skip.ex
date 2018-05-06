defmodule Exoda.Query.Skip do
  alias Ecto.Query
  alias Ecto.Query.QueryExpr

  @moduledoc """
  Functions to build $skip OData parameter
  """

  @doc """
  Builds a $skip OData query parameter
  """
  @spec add_skip(Map.t, Query.t) :: Map.t | no_return
  def add_skip(query_params, %Query{offset: nil}), do: query_params
  def add_skip(query_params, %Query{offset: %QueryExpr{expr: offset}}) do
    Map.put(query_params, "$skip", offset)
  end
end
