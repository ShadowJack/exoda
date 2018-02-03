defmodule Exoda.Command do
  @moduledoc """
  Module contains a part of implementation of `Ecto.Adapter` behaviour
  related to creating/updating/deleting data.
  """

  @typep repo :: Ecto.Repo.t()
  @typep options :: Keyword.t()
  @typep schema_meta :: Ecto.Adapter.schema_meta()
  @typep fields :: Ecto.Adapter.fields()
  @typep on_conflict :: Ecto.Adapter.on_conflict()
  @typep returning :: Ecto.Adapter.returning()
  @typep filters :: Ecto.Adapter.filters()
  @typep constraints :: Ecto.Adapter.constraints()
  
  @doc """
  Creates multiple entries in the OData server
  """
  @spec insert_all(
          repo,
          schema_meta(),
          header :: [atom],
          [fields()],
          on_conflict(),
          returning(),
          options
        ) :: {integer, [[term]] | nil} | no_return
  def insert_all(repo, schema_meta, header, fields_list, on_conflict, returning, opts) do
    # TODO: check if batch operations are supported by the remote server
    # If not then create entities one by one
    raise "Not implemented"
  end

  @doc """
  Creates a single new entity in the OData server.

  The primary key of the created entry will be automatically included in `returning`.
  """
  @spec insert(
          repo,
          schema_meta(),
          fields(),
          on_conflict(),
          returning(),
          options
        ) :: {:ok, fields()} | {:invalid, constraints()} | no_return
  def insert(repo, schema_meta, fields, on_conflict, returning, opts) do
    raise "Not implemented"
  end

  @doc """
  Updates a single entity with the given filters.

  While `filters` can be any record column, it is expected that
  at least the primary key (or any other key that uniquely
  identifies an existing record) be given as a filter. Therefore,
  in case there is no record matching the given filters,
  `{:error, :stale}` is returned.
  """
  @spec update(
          repo,
          schema_meta(),
          fields(),
          filters(),
          returning(),
          options
        ) ::
          {:ok, fields()}
          | {:invalid, constraints()}
          | {:error, :stale}
          | no_return
  def update(repo, schema_meta, fields, filters, returning, opts) do
    raise "Not implemented"
  end

  @doc """
  Deletes a single entity with the given filters.

  While `filters` can be any record column, it is expected that
  at least the primary key (or any other key that uniquely
  identifies an existing record) be given as a filter. Therefore,
  in case there is no record matching the given filters,
  `{:error, :stale}` is returned.
  """
  @spec delete(repo, schema_meta(), filters(), options) ::
          {:ok, fields()}
          | {:invalid, constraints()}
          | {:error, :stale}
          | no_return
  def delete(repo, schema_meta, filters, opts) do
    raise "Not implemented"
  end
end
