defmodule Exoda.Client do
  use GenServer

  @moduledoc """
  This module should be used to make http requests to the remote OData server.
  """

  @typep repo :: Ecto.Repo.t()
  @typep options :: Keyword.t()

  @doc """
  Provide Genserver.Spec.worker description so that external supervisor
  would know how to run the Exoda.Client process.
  It's called from `Ecto.Repo.Supervisor.init/2`
  """
  @spec child_spec(repo, options) :: Supervisor.Spec.child_spec
  def child_spec(_repo, opts) do
    Supervisor.Spec.worker(Exoda.Client, opts)
  end

  @doc false
  @spec start_link(options) :: GenServer.on_start
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc false
  @spec init(options) :: {:ok, term}
  def init(opts) do
    case Keyword.fetch(opts, :url) do
      {:ok, service_url} ->
        {:ok, %{:service_url => service_url}}

      :error ->
        raise ArgumentError, "Expected :url is not configured."
    end
  end
end
