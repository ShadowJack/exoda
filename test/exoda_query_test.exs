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

    test "can return only full association" do
      query = from p in Product, 
        join: pd in assoc(p, :product_detail), 
        select: pd 
      results = Repo.all(query)
      assert length(results) > 0
      #TODO: fix this test
      assert %ProductDetail{product_id: _} = hd(results)
    end

    @tag :skip
    test "associations without selects are not expanded" do
      query = from p in Product, 
        join: pd in assoc(p, :product_detail), 
        select: p 
      results = Repo.all(query)
      assert length(results) > 0
      #TODO: check that product_detail is not in expands of the request
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

  @tag :skip
  test "join with has_one association" do
    
  end

  @tag :skip
  test "join with many_to_many association" do
    
  end

  @tag :skip
  test "join nested associations" do
    
  end

  test "filter by joined associations" do
    query = from p in Product, 
      join: d in assoc(p, :product_detail), 
      where: like(d.details, "%product%")
    products = Repo.all(query)
    assert length(products) > 0
  end

  @tag :skip
  test "order_by option is ordering results" do
  end

  @tag :skip
  test "distinct option returns distinct results" do
  end

  @tag :skip
  test "`first` option returns the first result consideting order by option" do
  end

  @tag :skip
  test "group_by option is not supported" do
  end

  @tag :skip
  test "`last` option returns the last result consideting order by option" do
  end

  @tag :skip
  test "limit option limits number of products returned from the query" do
  end

  @tag :skip
  test "lock option is not supported" do
  end

  @tag :skip
  test "offset option skips firts results" do
  end

  @tag :skip
  test "preload option loads associations" do
  end

  @tag :skip
  test "select works for several sources" do
    #TODO: select from preloaded association too
  end

  @tag :skip
  test "subqueries are not supported" do
  end
end
