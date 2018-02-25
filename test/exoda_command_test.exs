defmodule ExodaCommandTest do
  use ExUnit.Case, async: false
  alias Exoda.Command, as: Cmd

  setup_all do
    startup_opts = [repo: Exoda.RepoMock, otp_app: :exoda]
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
      assert {:ok, _response} = Cmd.insert(Exoda.RepoMock, @schema_meta, @valid_fields, nil, @returning, @opts)
    end

    test "returning settings are respected" do
      assert {:ok, [{"ID", _id}]} = Cmd.insert(Exoda.RepoMock, @schema_meta, @valid_fields, nil, ["ID"], @opts)
    end

    test "if returning is not required, nothing is returned" do
      assert {:ok, []} = Cmd.insert(Exoda.RepoMock, @schema_meta, @valid_fields, nil, [], @opts)
    end
  end
end
