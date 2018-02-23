defmodule Exoda.Query do
  @moduledoc """
  Module contains a part of implementation of `Ecto.Adapter` behaviour
  related to querying data.
  """

  @typep repo :: Ecto.Repo.t()
  @typep prepared :: Ecto.Adapter.prepared()
  @typep options :: Keyword.t()
  @typep query_meta :: Ecto.Adapter.query_meta()
  @typep query :: Ecto.Query.t()
  @typep process :: Ecto.Adapter.process()
  @typep cached :: Ecto.Adapter.cached()

  @doc """
  Commands invoked to prepare a query for `all`, `update_all` and `delete_all`.

  The returned result is given to `execute/6`.
  """
  @spec prepare(atom :: :all | :update_all | :delete_all, query) ::
          {:cache, prepared} | {:nocache, prepared}
  def prepare(query_type, query) do
    raise "Not implemented"
  end

  @doc """
  Executes a previously prepared query.

  It returns a tuple containing the number of entries and
  the result set as a list of lists. The result set may also be
  `nil` if a particular operation does not support them.

  The `meta` field is a map containing some of the fields found
  in the `Ecto.Query` struct.

  It receives a process function that should be invoked for each
  selected field in the query result in order to convert them to the
  expected Ecto type. The `process` function will be nil if no
  result set is expected from the query.
  """
  @callback execute(repo, query_meta, query, params :: list(), process | nil, options) :: result
            when result: {integer, [[term]] | nil} | no_return,
                 query:
                   {:nocache, prepared}
                   | {:cached, (prepared -> :ok), cached}
                   | {:cache, (cached -> :ok), prepared}
  def execute(repo, query_meta, query, params, process, opts) do
    raise "Not implemented"
  end
end
