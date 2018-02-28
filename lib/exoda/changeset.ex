defmodule Exoda.Changeset do
  @moduledoc """
  Helper functions for Ecto changesets
  """
  
  @doc """
  Add odata type field to the changeset. 
  This field may be required for insert and update operations for entity types that take part in inheritance tree.

  Example:
  ```
  defmodule Example.FeaturedProduct do
    use Exoda.Schema
    import Ecto.Changeset
    import Exoda.Changeset

    @odata_type "ODataDemo.FeaturedProduct"
    schema "Products" do
      odata_type @odata_type
      field :name, :string, source: "Name"
    end

    def changeset(%FeaturedProduct{} = product, attrs) do
      product
      |> cast(attrs, [:id, :name])
      |> validate_required([:id, :name])
      |> add_odata_type(@odata_type)
    end
  end
  ```
  """
  @spec add_odata_type(Changeset.t, String.t) :: Changeset.t
  def add_odata_type(changeset, type) do
    Ecto.Changeset.force_change(changeset, :odata_type, type)
  end
end
