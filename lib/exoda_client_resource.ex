defmodule ExodaClient.EntityType do
  @moduledoc """
  Module that contains helper functions for querying the resource on OData server.

  Basic usage:
  ```
  defmodule Categories do
    use ExodaClient.EntityType 'http://services.odata.org/V3/Northwind/Northwind.svc/Categories'

    def get_description(id) do
      get(id: id, select: ['Description'])
    end
  end
  ```
  """

  @doc """
  Hello world.

  ## Examples

      iex> ExodaClient.hello
      :world

  """
  def hello do
    :world
  end
end
