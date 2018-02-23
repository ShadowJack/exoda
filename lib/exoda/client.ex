defmodule Exoda.Client do
  alias HTTPoison.{Response, AsyncResponse, Error}

  @moduledoc """
  This module defines a behaviour that http client should implement
  """

  @doc """
  Send a generic request, see `HTTPoison.Base.request/5`
  """
  @callback request(
              method :: atom,
              url :: String.t(),
              body :: any,
              headers :: HTTPoison.headers(),
              opts :: Keyword.t()
            ) :: {:ok, Response.t() | AsyncResponse.t()} | {:error, Error.t()}

  @doc """
  Send a generic request, see `HTTPoison.Base.request!/5`
  May raise errors.
  """
  @callback request!(
              method :: atom,
              url :: String.t(),
              body :: any,
              headers :: HTTPoison.headers(),
              opts :: Keyword.t()
            ) :: Response.t() | AsyncResponse.t()

  @doc """
  Issues a GET request to the given url, see `HTTPoison.Base.get/3`
  """
  @callback get(url :: String.t(), headers :: HTTPoison.headers(), opts :: Keyword.t()) ::
              {:ok, Response.t() | AsyncResponse.t()} | {:error, Error.t()}

  @doc """
  Issues a GET request to the given url, raising an exception in case of
  failure. See `HTTPoison.Base.get!/3`
  """
  @callback get!(url :: String.t(), headers :: HTTPoison.headers(), opts :: Keyword.t()) ::
              Response.t() | AsyncResponse.t()

  @doc """
  Issues a PUT request to the given url.
  See `HTTPoison.Base.put/4`.
  """
  @callback put(
              url :: String.t(),
              body :: any,
              headers :: HTTPoison.headers(),
              opts :: Keyword.t()
            ) :: {:ok, Response.t() | AsyncResponse.t()} | {:error, Error.t()}

  @doc """
  Issues a PUT request to the given url, raising an exception in case of failure.
  See `HTTPoison.Base.put!/4`.
  """
  @callback put!(
              url :: String.t(),
              body :: any,
              headers :: HTTPoison.headers(),
              opts :: Keyword.t()
            ) :: Response.t() | AsyncResponse.t()

  @doc """
  Issues a HEAD request to the given url.
  See `HTTPoison.Base.head/3`
  """
  @callback head(url :: String.t(), headers :: HTTPoison.headers(), opts :: Keyword.t()) ::
              {:ok, Response.t() | AsyncResponse.t()} | {:error, Error.t()}

  @doc """
  Issues a HEAD request to the given url, raising an exception in case of failure.
  See `HTTPoison.Base.head!/3`
  """
  @callback head!(url :: String.t(), headers :: HTTPoison.headers(), opts :: Keyword.t()) ::
              Response.t() | AsyncResponse.t()

  @doc """
  Send a POST request. 
  See `HTTPoison.Base.post/4`.
  """
  @callback post(
              url :: String.t(),
              body :: any,
              headers :: HTTPoison.headers(),
              opts :: Keyword.t()
            ) :: {:ok, Response.t() | AsyncResponse.t()} | {:error, HTTPoison.Error.t()}

  @doc """
  Send a POST request, raising an exception in case of failure. 
  See `HTTPoison.Base.post!/4`.
  """
  @callback post!(
              url :: String.t(),
              body :: any,
              headers :: HTTPoison.headers(),
              opts :: Keyword.t()
            ) :: Response.t() | AsyncResponse.t()

  @doc """
  Send a PATCH request. 
  See `HTTPoison.Base.patch/4`.
  """
  @callback patch(
              url :: String.t(),
              body :: any,
              headers :: HTTPoison.headers(),
              opts :: Keyword.t()
            ) :: {:ok, Response.t() | AsyncResponse.t()} | {:error, HTTPoison.Error.t()}

  @doc """
  Send a PATCH request, raising an exception in case of failure. 
  See `HTTPoison.Base.patch!/4`.
  """
  @callback patch!(
              url :: String.t(),
              body :: any,
              headers :: HTTPoison.headers(),
              opts :: Keyword.t()
            ) :: Response.t() | AsyncResponse.t()

  @doc """
  Issues a DELETE request to the given url.
  See `HTTPoison.Base.delete/3`
  """
  @callback delete(url :: String.t(), headers :: HTTPoison.headers(), opts :: Keyword.t()) ::
              {:ok, Response.t() | AsyncResponse.t()} | {:error, Error.t()}

  @doc """
  Issues a DELETE request to the given url, raising an exception in case of failure.
  See `HTTPoison.Base.delete!/3`
  """
  @callback delete!(url :: String.t(), headers :: HTTPoison.headers(), opts :: Keyword.t()) ::
              Response.t() | AsyncResponse.t()

  @doc """
  Issues a OPTIONS request to the given url.
  See `HTTPoison.Base.options/3`
  """
  @callback options(url :: String.t(), headers :: HTTPoison.headers(), opts :: Keyword.t()) ::
              {:ok, Response.t() | AsyncResponse.t()} | {:error, Error.t()}

  @doc """
  Issues a OPTIONS request to the given url, raising an exception in case of failure.
  See `HTTPoison.Base.options/3`
  """
  @callback options!(url :: String.t(), headers :: HTTPoison.headers(), opts :: Keyword.t()) ::
              Response.t() | AsyncResponse.t()
end
