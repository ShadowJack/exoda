defmodule ExodaQueryTest do
  use ExUnit.Case, async: false
  import Ecto.Query
  alias Exoda.{Query, Fakes.Repo, Fakes.Product}

  setup do
    {:ok, _} = start_supervised({Exoda.Fakes.Repo, []})
    :ok
  end
  
  test "all entries are successfully fetched" do
    entries = Repo.all(Product)
    assert length(entries) > 0
    assert %Product{id: _} = hd(entries)
  end

  test "`select` option is restricting returned fields" do
    query = from p in Product, select: p.name
    entries = Repo.all(query)
    assert length(entries) > 0
    assert Enum.all?(entries, fn name -> is_binary(name) end)

    query = from p in Product, select: [p.name, p.price]
    entries = Repo.all(query)
    assert length(entries) > 0
    assert Enum.all?(entries, fn arr -> is_list(arr) && length(arr) == 2 end)
  end

  describe "`where` option" do
    test "comparison operators" do
      query = from p in Product, where: p.price > 20.0
      entries = Repo.all(query)
      assert length(entries) > 0
      assert Enum.all?(entries, fn p -> p.price > 20.0 end)

      query = from p in Product, where: p.price >= 20.9
      entries = Repo.all(query)
      assert length(entries) > 0
      assert Enum.all?(entries, fn p -> p.price >= 20.9 end)
      assert Enum.any?(entries, fn p -> p.price == 20.9 end)

      query = from p in Product, where: p.price < 20.0
      entries = Repo.all(query)
      assert length(entries) > 0
      assert Enum.all?(entries, fn p -> p.price < 20.0 end)

      query = from p in Product, where: p.price <= 20.9
      entries = Repo.all(query)
      assert length(entries) > 0
      assert Enum.all?(entries, fn p -> p.price <= 20.9 end)
      assert Enum.any?(entries, fn p -> p.price == 20.9 end)

      query = from p in Product, where: p.price == 2.5
      entries = Repo.all(query)
      assert length(entries) == 1
      assert Enum.all?(entries, fn p -> p.price == 2.5 end)

      query = from p in Product, where: p.price != 2.5
      entries = Repo.all(query)
      assert length(entries) > 0
      assert Enum.all?(entries, fn p -> p.price != 2.5 end)
    end

    test "several conditions" do
      query = from p in Product, where: p.price > 3.0 and p.name == "Milk"
      query = from p in query, where: p.rating <= 4
      entries = Repo.all(query)
      assert length(entries) > 0
      assert Enum.all?(entries, fn p -> p.price > 3.0 and p.rating < 4 end)
    end

    @tag :skip
    test "bind valiables" do
      
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
  test "limit option limits number of entries returned from the query" do
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
