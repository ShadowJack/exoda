defmodule ExodaCommandTest do
  use Exoda.BaseCase, async: true
  # use ExUnit.Case, async: true
  alias Exoda.Command, as: Cmd

  describe "insert one entry" do
    test "return=minimal preference is passed in request" do
      result = Cmd.insert(nil, nil, nil, nil, nil, nil, [])
    end
  end
end
