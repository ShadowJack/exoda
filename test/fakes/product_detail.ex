defmodule Exoda.Fakes.ProductDetail do
  use Exoda.Schema
  import Ecto.Changeset
  import Exoda.Changeset


  schema "ProductDetails" do
    odata_type "ODataDemo.ProductDetail"
    field :details, :string, source: "Details"
    belongs_to :product, Exoda.Fakes.Product, primary_key: true, source: "ProductID"
  end

  @doc false
  def changeset(%Exoda.Fakes.ProductDetail{} = product_detail, attrs) do
    product_detail
    |> cast(attrs, [:product_id, :details])
    |> validate_required([:product_id])
    |> add_odata_type(@odata_type)
  end
end
