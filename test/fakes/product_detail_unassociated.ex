defmodule Exoda.Fakes.ProductDetailUnassociated do
  use Exoda.Schema
  import Ecto.Changeset
  import Exoda.Changeset

  schema "ProductDetailsUnassociated" do
    field :details, :string, source: "Details"
    field :product_id, :id, primary_key: true, source: "ProductID"
  end
end
