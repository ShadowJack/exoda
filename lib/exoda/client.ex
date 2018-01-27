defmodule Exoda.Client do
  use GenServer

  @moduledoc """
  This module should be used to make http requests to the remote OData server.

  """

  def init(opts) do
    case Keyword.fetch(opts, :url) do
      {:ok, service_url} -> 
        {:ok, %{:service_url => service_url}}
      :error -> 
        raise ArgumentError, "Expected :url is not configured."
    end
  end
end
