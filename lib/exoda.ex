defmodule Exoda do
  require Logger

  @moduledoc """
  An implementation of `Ecto.Adapter` that can be used
  to access remote endpoints supporting OData v4 protocol
  """

  @typep options :: Keyword.t()
  @typep repo :: Ecto.Repo.t()

  @behaviour Ecto.Adapter

  @impl true
  defmacro __before_compile__(_), do: :ok

  @impl true
  @spec ensure_all_started(repo, type :: :application.restart_type()) ::
          {:ok, [atom]} | {:error, atom}
  def ensure_all_started(_repo, type) do
    with {:ok, _} <- Application.ensure_all_started(:httpoison, type),
         {:ok, _} <- Application.ensure_all_started(:logger, type) do
      {:ok, [:httpoison, :logger]}
    else
      {:error, {app, _}} -> {:error, app}
    end
  end

  @doc false
  @impl true
  @spec child_spec(repo, options) :: :supervisor.child_spec()
  defdelegate child_spec(repo, opts), to: Exoda.ServiceDescription

  #
  ## Types

  @doc false
  @impl true
  defdelegate loaders(primitive, type), to: Exoda.Types

  @doc false
  @impl true
  defdelegate dumpers(primitive, type), to: Exoda.Types

  @doc false
  @impl true
  defdelegate autogenerate(id_type), to: Exoda.Types


  #
  ## Queries

  @doc false
  @impl true
  defdelegate prepare(query_type, query), to: Exoda.Query

  @doc false
  @impl true
  defdelegate execute(repo, query_meta, query, params, process, opts), to: Exoda.Query 


  #
  # Commands

  @doc false
  @impl true
  defdelegate insert_all(repo, schema_meta, header, fields_list, on_conflict, returning, opts), to: Exoda.Command

  @doc false
  @impl true
  defdelegate insert(repo, schema_meta, fields, on_conflict, returning, opts), to: Exoda.Command

  @doc false
  @impl true
  defdelegate update(repo, schema_meta, fields, filters, returning, opts), to: Exoda.Command

  @doc false
  @impl true
  defdelegate delete(repo, schema_meta, filters, opts), to: Exoda.Command
end
