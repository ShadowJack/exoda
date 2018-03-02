defmodule Exoda.Fakes.Product do
  use Exoda.Schema
  import Ecto.Changeset
  import Exoda.Changeset
  alias Exoda.Fakes.Product


  @primary_key {:id, :id, autogenerate: false, source: "ID"}
  schema "Products" do
    odata_type "ODataDemo.Product"
    field :description, :string, source: "Description"
    field :discontinued_date, :utc_datetime, source: "DiscontinuedDate"
    field :name, :string, source: "Name", read_after_writes: true
    field :price, :float, source: "Price"
    field :rating, :integer, source: "Rating"
    field :release_date, :utc_datetime, source: "ReleaseDate", read_after_writes: true
  end

  @doc false
  def changeset(%Product{} = product, attrs) do
    product
    |> cast(attrs, [:id, :name, :description, :release_date, :discontinued_date, :rating, :price])
    |> validate_required([:id, :release_date])
    |> add_odata_type(@odata_type)
  end
end
