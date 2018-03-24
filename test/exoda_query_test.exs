defmodule ExodaQueryTest do
  use ExUnit.Case, async: false
  import Ecto.Query
  alias Exoda.{Query, Fakes.Repo, Fakes.Product}

  setup do
    {:ok, _} = start_supervised({Exoda.Fakes.Repo, []})
    :ok
  end
  
  test "all products are successfully fetched" do
    products = Repo.all(Product)
    assert length(products) > 0
    assert %Product{id: _} = hd(products)
  end

  test "`select` option is restricting returned fields" do
    query = from p in Product, select: p.name
    products = Repo.all(query)
    assert length(products) > 0
    assert Enum.all?(products, fn name -> is_binary(name) end)

    query = from p in Product, select: [p.name, p.price]
    products = Repo.all(query)
    assert length(products) > 0
    assert Enum.all?(products, fn arr -> is_list(arr) && length(arr) == 2 end)
  end

  describe "`where` option" do
    test "comparison operators" do
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

    test "several conditions" do
      query = from p in Product, where: p.price > 3.0 and p.name == "Milk"
      query = from p in query, where: p.rating <= 4
      products = Repo.all(query)
      assert length(products) > 0
      assert Enum.all?(products, fn p -> p.price > 3.0 and p.rating < 4 end)
    end

    test "`not` option negates expression" do
      query = from p in Product, where: not(p.name == "Milk")
      products = Repo.all(query)
      assert length(products) > 0
      assert Enum.all?(products, fn p -> p.name != "Milk" end)
    end

    test "`is_nil` function" do
      query = from p in Product, where: is_nil(p.discontinued_date)
      products = Repo.all(query)
      assert length(products) > 0
      assert Enum.all?(products, fn p -> p.discontinued_date == nil end)
    end

    test "ends with" do
      query = from p in Product, where: like(p.name, "%soda")
      products = Repo.all(query)
      assert length(products) > 0
      assert Enum.all?(products, fn p -> String.ends_with?(p.name, "soda") end)
    end

    test "starts with" do
      query = from p in Product, where: like(p.name, "Fruit %")
      products = Repo.all(query)
      assert length(products) > 0
      assert Enum.all?(products, fn p -> String.starts_with?(p.name, "Fruit ") end)
    end

    test "contains" do
      query = from p in Product, where: like(p.name, "%monad%")
      products = Repo.all(query)
      assert length(products) > 0
      assert Enum.all?(products, fn p -> String.contains?(p.name, "monad") end)
    end

    test "equals" do
      query = from p in Product, where: like(p.name, "Milk")
      products = Repo.all(query)
      assert length(products) > 0
      assert Enum.all?(products, fn p -> p.name == "Milk" end)
    end

    test "bind parameters" do
      name = "Milk"
      min_price = 1
      query = from p in Product, where: p.name == ^name and p.price >= ^min_price
      product = Repo.one(query)
      assert product.name == name
      assert product.price >= min_price
    end

    test "dynamic fields" do
      price_or_rating = :rating
      query = from p in Product, where: field(p, ^price_or_rating) >= 4
      products = Repo.all(query)
      assert length(products) > 0
      assert Enum.all?(products, fn p -> p.rating >= 4 end)
    end

    test "fragments" do
      query = from p in Product, where: fragment("tolower(?)", p.name) == "milk"
      assert %Product{name: "Milk"} = Repo.one(query)
    end

    test "type casting" do
      rating = 4
      query = from p in Product, where: fragment("?", p.rating) >= type(p.price, :integer)
      assert %Product{name: "Milk"} = Repo.one(query)
    end
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
  test "join option is not supported" do
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
