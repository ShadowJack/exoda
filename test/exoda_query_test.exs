defmodule ExodaQueryTest do
  use ExUnit.Case, async: false
  import Ecto.Query
  alias Exoda.Query
  alias Exoda.Fakes.{Repo, Product, ProductDetail, ProductDetailUnassociated, Category}

  setup do
    {:ok, _} = start_supervised({Exoda.Fakes.Repo, []})
    :ok
  end
  
  test "all products are successfully fetched" do
    products = Repo.all(Product)
    assert length(products) > 0
    assert %Product{id: _} = hd(products)
  end

  describe "$select option" do
    test "can return only one field" do
      query = from p in Product, select: p.name
      products = Repo.all(query)
      assert length(products) > 0
      assert Enum.all?(products, fn name -> is_binary(name) end)
    end

    test "can return array" do
      query = from p in Product, select: [p.name, p.price]
      products = Repo.all(query)
      assert length(products) > 0
      assert Enum.all?(products, fn arr -> is_list(arr) && length(arr) == 2 end)
    end

    test "can return tuple" do
      query = from p in Product, 
        select: {p.name, p.rating}
      results = Repo.all(query)
      assert length(results) > 0
      assert {_, _} = hd(results)
    end

    test "can return tuple with association" do
      query = from p in Product, 
        join: c in assoc(p, :categories), 
        select: {p.id, p.name, c.name}
      results = Repo.all(query)
      assert length(results) > 0
      assert {_id, _name, _cat_name} = List.first(results)
    end

    test "can't return only full association" do
      assert_raise(RuntimeError, fn -> 
        query = from p in Product, 
          join: pd in assoc(p, :product_detail), 
          select: pd 
        results = Repo.all(query)
      end)
    end

    test "at least one field from the main source should be specified" do
      assert_raise(RuntimeError, fn -> 
        query = from p in Product, 
          join: pd in assoc(p, :product_detail), 
          select: pd.details 
        results = Repo.all(query)
      end)
    end

    test "associations without selects are not expanded" do
      query = from p in Product, 
        join: pd in assoc(p, :product_detail), 
        select: p.id
      results = Repo.all(query)
      # it's checked that product_detail is not in expands of the request 
      # inside the fake http client
      assert length(results) > 0
    end
  end

  describe "$where option" do
    test "supports comparison operators" do
      query = from p in Product, where: p.price > 20.0
      products = Repo.all(query)
      assert length(products) > 0
      assert Enum.all?(products, fn p -> p.price > 20.0 end)

      query = from p in Product, where: p.price >= 20.9
      products = Repo.all(query)
      assert length(products) > 0
      assert Enum.all?(products, fn p -> p.price >= 20.9 end)
      assert Enum.any?(products, fn p -> p.price == 20.9 end)

      query = from p in Product, where: p.price < 20.0
      products = Repo.all(query)
      assert length(products) > 0
      assert Enum.all?(products, fn p -> p.price < 20.0 end)

      query = from p in Product, where: p.price <= 20.9
      products = Repo.all(query)
      assert length(products) > 0
      assert Enum.all?(products, fn p -> p.price <= 20.9 end)
      assert Enum.any?(products, fn p -> p.price == 20.9 end)

      query = from p in Product, where: p.price == 2.5
      products = Repo.all(query)
      assert length(products) == 1
      assert Enum.all?(products, fn p -> p.price == 2.5 end)

      query = from p in Product, where: p.price != 2.5
      products = Repo.all(query)
      assert length(products) > 0
      assert Enum.all?(products, fn p -> p.price != 2.5 end)
    end

    test "supports several conditions" do
      query = from p in Product, where: p.price > 3.0 and p.name == "Milk"
      query = from p in query, where: p.rating <= 4
      products = Repo.all(query)
      assert length(products) > 0
      assert Enum.all?(products, fn p -> p.price > 3.0 and p.rating < 4 end)
    end

    test "supports `not` option that negates expression" do
      query = from p in Product, where: not(p.name == "Milk")
      products = Repo.all(query)
      assert length(products) > 0
      assert Enum.all?(products, fn p -> p.name != "Milk" end)
    end

    test "supports `is_nil` function" do
      query = from p in Product, where: is_nil(p.discontinued_date)
      products = Repo.all(query)
      assert length(products) > 0
      assert Enum.all?(products, fn p -> p.discontinued_date == nil end)
    end

    test "supports `like` function: ends with" do
      query = from p in Product, where: like(p.name, "%soda")
      products = Repo.all(query)
      assert length(products) > 0
      assert Enum.all?(products, fn p -> String.ends_with?(p.name, "soda") end)
    end

    test "supports `like` function: starts with" do
      query = from p in Product, where: like(p.name, "Fruit %")
      products = Repo.all(query)
      assert length(products) > 0
      assert Enum.all?(products, fn p -> String.starts_with?(p.name, "Fruit ") end)
    end

    test "supports `like` function: contains" do
      query = from p in Product, where: like(p.name, "%monad%")
      products = Repo.all(query)
      assert length(products) > 0
      assert Enum.all?(products, fn p -> String.contains?(p.name, "monad") end)
    end

    test "supports `like` function: equals" do
      query = from p in Product, where: like(p.name, "Milk")
      products = Repo.all(query)
      assert length(products) > 0
      assert Enum.all?(products, fn p -> p.name == "Milk" end)
    end

    test "supports binded parameters" do
      name = "Milk"
      min_price = 1
      query = from p in Product, where: p.name == ^name and p.price >= ^min_price
      product = Repo.one(query)
      assert product.name == name
      assert product.price >= min_price
    end

    test "supports dynamic fields" do
      price_or_rating = :rating
      query = from p in Product, where: field(p, ^price_or_rating) >= 4
      products = Repo.all(query)
      assert length(products) > 0
      assert Enum.all?(products, fn p -> p.rating >= 4 end)
    end

    test "supports fragments" do
      query = from p in Product, where: fragment("tolower(?)", p.name) == "milk"
      assert %Product{name: "Milk"} = Repo.one(query)
    end
  end

  test "join without associatoin is not supported" do
    assert_raise(RuntimeError, "Association path from #{Product} to #{ProductDetailUnassociated} is not found", fn -> 
      query = from p in Product, 
        join: pd in ProductDetailUnassociated, 
        on: p.id == pd.product_id,
        where: like(pd.details, "%milk%")
      Repo.all(query)
    end)
  end

  test "filter by joined associations" do
    query = from p in Product, 
      join: d in assoc(p, :product_detail), 
      where: like(d.details, "%product%")
    products = Repo.all(query)
    assert length(products) > 0
  end

  describe "`order_by` option" do
    test "with keyword list" do
      query = from p in Product, order_by: [desc: p.rating, asc: p.price]
      products = Repo.all(query)

      assert_sort_by_rating_price(products, true)
    end

    test "with several clauses works as one compound clause" do
      query = from p in Product, order_by: p.rating, order_by: p.price
      products = Repo.all(query)

      assert_sort_by_rating_price(products)
    end

    test "supports atom values" do
      query = from p in Product, order_by: [:rating, :price]
      products = Repo.all(query)

      assert_sort_by_rating_price(products)
    end

    test "supports ordering by associated fields" do
      query = from p in Product, 
        join: pd in assoc(p, :product_detail), 
        select: {p.id, pd.details},
        order_by: pd.details
      results = Repo.all(query)

      details = Enum.map(results, fn {_, d} -> d end)
      assert details == Enum.sort(details)
    end

    defp assert_sort_by_rating_price(products, desc_rating \\ false) do
      ratings = Enum.map(products, &(&1.rating))
      assert Enum.sort(ratings, fn r1, r2 -> 
        if desc_rating, do: r1 >= r2, else: r1 <= r2 
      end) == ratings

      products_by_rating = Enum.chunk_by(products, &(&1.rating))
      assert Enum.all?(products_by_rating, fn prods ->
        Enum.sort(prods, &(&1.price <= &2.price)) == prods
      end)
    end
  end

  test "`distinct` option is not supported" do
    assert_raise(RuntimeError, fn -> 
      query = from p in Product, distinct: true, select: p.rating
      Repo.all(query)
    end)
  end

  @tag :skip
  test "group_by option is not supported" do
  end

  test "`first` option returns the first result" do
    products = Product |> first(:rating) |> Repo.all()

    assert length(products) == 1
    assert hd(products).rating == 1
  end

  describe "`limit` option" do
    test "restricts the number of products returned from the query" do
      query = from p in Product, limit: 2, select: p.id
      products = Repo.all(query)

      assert length(products) == 2
    end

    test "takes `order_by` option into account" do
      query = from p in Product, 
        limit: 2, 
        order_by: :rating,
        select: p.rating
      ratings = Repo.all(query)

      assert length(ratings) == 2
      assert List.first(ratings) <= List.last(ratings)
    end
  end

  test "lock option is not supported" do
    assert_raise(RuntimeError, fn -> 
      query = from p in Product, lock: "FOR SHARE NOWAIT"
      Repo.all(query)
    end)
  end

  @tag :skip
  test "offset option skips firts results" do
  end

  @tag :skip
  test "`last` option returns the last result consideting order by option" do
  end

  @tag :skip
  test "preload option loads associations" do
  end

  @tag :skip
  test "subqueries are not supported" do
  end
end
