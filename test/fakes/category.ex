defmodule Exoda.Fakes.Category do
  use Exoda.Schema
  import Ecto.Changeset
  import Exoda.Changeset


  @primary_key {:id, :id, autogenerate: false, source: "ID"}
  schema "Categories" do
    odata_type "ODataDemo.Category"
    field :name, :string, source: "Name", read_after_writes: true
    many_to_many :products, {"Products", Exoda.Fakes.Product}, join_through: "Categories"
  end

  @doc false
  def changeset(%Exoda.Fakes.Category{} = category, attrs) do
    category
    |> cast(attrs, [:id, :name])
    |> validate_required([:id])
    |> add_odata_type(@odata_type)
  end
end
