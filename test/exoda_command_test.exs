defmodule ExodaCommandTest do
  use ExUnit.Case, async: false
  alias Exoda.Command, as: Cmd
  alias Exoda.RepoMock

  setup_all do
    startup_opts = [repo: RepoMock, otp_app: :exoda]
    {:ok, _} = start_supervised({Exoda.ServiceDescription, startup_opts})
    :ok
  end

  @schema_meta %{
    autogenerate_id: nil,
    context: nil,
    schema: Exoda.Fakes.Product,
    source: {nil, "Products"}
  }
  @valid_fields [
    {"Description", "some description"}, 
    {"DiscontinuedDate", "2010-04-17T10:20:30.400000Z"},
    {"ID", 1},
    {"Name", "some name"},
    {"@odata.type", "ODataDemo.Product"},
    {"Price", 120.5},
    {"Rating", 42},
    {"ReleaseDate", "2010-04-17T13:05:50.555000Z"}
  ]
  @returning ["ID", "ReleaseDate", "Name"]
  @opts [skip_transaction: true]


  describe "insert one entry" do
    test "valid entry is successfully created" do
      assert {:ok, _response} = Cmd.insert(RepoMock, @schema_meta, @valid_fields, nil, @returning, @opts)
    end

    test "returning settings are respected" do
      assert {:ok, [{"ID", _id}]} = Cmd.insert(RepoMock, @schema_meta, @valid_fields, nil, ["ID"], @opts)
    end

    test "if returning is not required, nothing is returned" do
      assert {:ok, []} = Cmd.insert(RepoMock, @schema_meta, @valid_fields, nil, [], @opts)
    end
  end


  describe "update one entry" do
    setup do
      all_returning = @valid_fields |> Enum.map(fn {name, _} -> name end)
      {:ok, product} = Cmd.insert(RepoMock, @schema_meta, @valid_fields, nil, all_returning, @opts)
      {:ok, %{product: Map.new(product)}}
    end

    test "valid entry is successfully updated", %{product: %{"ID" => id}} do
      assert {:ok, updated} = Cmd.update(RepoMock, @schema_meta, [{"Name", "Updated name"}], [{"ID", id }], @returning, @opts)
      assert Map.new(updated) |> Map.fetch!("Name") == "Updated name"
    end

    test "returning settings are respected", %{product: %{"ID" => id}} do
      assert {:ok, [{"ID", ^id}]} = Cmd.update(RepoMock, @schema_meta, @valid_fields, [{"ID", id }], ["ID"], @opts)
    end

    test "if returning is not required, nothing is returned", %{product: %{"ID" => id}} do
      assert {:ok, []} == Cmd.update(RepoMock, @schema_meta, @valid_fields, [{"ID", id}], [], @opts)
    end

    @tag :skip
    test "handles navigation properties update properly" do
      #TODO:
      # For single-valued navigation properties this replaces the relationship. 
      # For collection-valued navigation properties this adds to the relationship
    end
  end
end
