defmodule Exoda.Client.Http do
  require Logger

  @moduledoc """
  This module implements `Exoda.Client` behaviour 
  via delegating calls to HTTPoison library.
  """

  @behaviour Exoda.Client


  @impl true
  defdelegate request(method, url, body \\ "", headers \\ [], opts \\ []), to: HTTPoison

  @impl true
  defdelegate request!(method, url, body \\ "", headers \\ [], opts \\ []), to: HTTPoison

  @impl true
  defdelegate get(url, headers \\ [], opts \\ []), to: HTTPoison

  @impl true
  defdelegate get!(url, headers \\ [], opts \\ []), to: HTTPoison

  @impl true
  defdelegate put(url, body \\ "", headers \\ [], opts \\ []), to: HTTPoison

  @impl true
  defdelegate put!(url, body \\ "", headers \\ [], opts \\ []), to: HTTPoison

  @impl true
  defdelegate head(url, headers \\ [], opts \\ []), to: HTTPoison

  @impl true
  defdelegate head!(url, headers \\ [], opts \\ []), to: HTTPoison

  @impl true
  defdelegate post(url, body \\ "", headers \\ [], opts \\ []), to: HTTPoison

  @impl true
  defdelegate post!(url, body \\ "", headers \\ [], opts \\ []), to: HTTPoison

  @impl true
  defdelegate patch(url, body \\ "", headers \\ [], opts \\ []), to: HTTPoison

  @impl true
  defdelegate patch!(url, body \\ "", headers \\ [], opts \\ []), to: HTTPoison

  @impl true
  defdelegate delete(url, headers \\ [], opts \\ []), to: HTTPoison

  @impl true
  defdelegate delete!(url, headers \\ [], opts \\ []), to: HTTPoison

  @impl true
  defdelegate options(url, headers \\ [], opts \\ []), to: HTTPoison

  @impl true
  defdelegate options!(url, headers \\ [], opts \\ []), to: HTTPoison
end
