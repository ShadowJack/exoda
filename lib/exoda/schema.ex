defmodule Exoda.Schema do
  @moduledoc """
  Helper functions and macros to be used in schema definitions
  """

  defmacro __using__(_) do
    quote do
      use Ecto.Schema

      import Exoda.Schema
    end
  end

  @doc """
  Add fully qualified odata entity type name to a schema definition.
  It may be required for entity types that take part in inheritance.

  ```
  defmodule Example.FeaturedProduct do
    use Exoda.Schema

    schema "Products" do
      odata_type "ODataDemo.FeaturedProduct"
    end
  end
  ```
  """
  defmacro odata_type(type) do
    quote do
      field :odata_type, :string, source: "@odata.type", default: unquote(type)
    end
  end

end
