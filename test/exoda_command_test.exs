defmodule ExodaCommandTest do
  use ExUnit.Case, async: false
  alias Exoda.Command, as: Cmd
  alias Exoda.Fakes.Repo

  setup_all do
    startup_opts = [repo: Repo, otp_app: :exoda]
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
      assert {:ok, _response} = Cmd.insert(Repo, @schema_meta, @valid_fields, nil, @returning, @opts)
    end

    test "returning settings are respected" do
      assert {:ok, [{"ID", _id}]} = Cmd.insert(Repo, @schema_meta, @valid_fields, nil, ["ID"], @opts)
    end

    test "if returning is not required, nothing is returned" do
      assert {:ok, []} = Cmd.insert(Repo, @schema_meta, @valid_fields, nil, [], @opts)
    end
  end


  describe "update one entry" do
    test "valid entry is successfully updated" do
      assert {:ok, updated} = Cmd.update(Repo, @schema_meta, [{"Name", "Updated name"}], [{"ID", 1 }], @returning, @opts)
      assert Map.new(updated) |> Map.fetch!("Name") == "Updated name"
    end

    test "returning settings are respected" do
      assert {:ok, [{"ID", 1}]} == Cmd.update(Repo, @schema_meta, @valid_fields, [{"ID", 1 }], ["ID"], @opts)
    end

    test "if returning is not required, nothing is returned" do
      assert {:ok, []} == Cmd.update(Repo, @schema_meta, @valid_fields, [{"ID", 1}], [], @opts)
    end

    test "error is returned when primary key is not passed in the filters" do
      assert {:error, :stale} == Cmd.update(Repo, @schema_meta, @valid_fields, [], [], [])
    end

    @tag :skip
    test "handles navigation properties update properly" do
      #TODO:
      # For single-valued navigation properties this replaces the relationship. 
      # For collection-valued navigation properties this adds to the relationship
    end
  end


  describe "delete one entry" do
    test "entry is successfully deleted" do
      assert {:ok, _} = Cmd.delete(Repo, @schema_meta, [{"ID", 1 }], [])
    end
  
    test "error is returned when primary key is not passed in the filters" do
      assert {:error, :stale} == Cmd.delete(Repo, @schema_meta, [], [])
    end
  
    @tag :skip
    test "associations are deleted when entry is deleted" do
      
    end
  end
end
