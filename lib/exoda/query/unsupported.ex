defmodule Exoda.Query.Unsupported do
  alias Ecto.Query

  @moduledoc """
  Checks for expressions that are not supported by OData protocol.
  """

  @doc """
  `distinct` option is not supported by OData.
  """
  @spec add_distinct(Map.t, Query.t) :: Map.t | no_return
  def add_distinct(params, %Query{distinct: nil}), do: params
  def add_distinct(_, _) do
    raise "`distinct` expression is not supported by OData."
  end

  @doc """
  `lock` option is not supported by OData.
  """
  @spec add_lock(Map.t, Query.t) :: Map.t | no_return
  def add_lock(params, %Query{lock: nil}), do: params
  def add_lock(_, _) do
    raise "`lock` expression is not supported by OData."
  end
end
