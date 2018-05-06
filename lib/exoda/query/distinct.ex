defmodule Exoda.Query.Distinct do

  @doc """
  Distinc option is not supported by OData.
  """
  @spec add_distinct(Map.t, Ecto.Query.t) :: Map.t | no_return
  def add_distinct(params, %Ecto.Query{distinct: nil}), do: params
  def add_distinct(_, _) do
    raise "`distinct` expression is not supported by OData."
  end
end
