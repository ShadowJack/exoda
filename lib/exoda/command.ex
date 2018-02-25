defmodule Exoda.Command do
  require Logger

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

  @client Application.get_env(:exoda, :client, Exoda.Client.Http)

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
          schema_meta,
          fields,
          on_conflict,
          returning,
          options
        ) :: {:ok, fields} | {:error, any} | {:invalid, constraints} | no_return
  def insert(repo, schema_meta, fields, _on_conflict, returning, opts) do
    Logger.debug("""
    repo: #{inspect(repo)}, 
    meta: #{inspect(schema_meta)},
    fields: #{inspect(fields)},
    returning: #{inspect(returning)},
    opts: #{inspect(opts)}
    """)

    {url, body, headers} = prepare_insert_request(schema_meta, fields, returning)

    case @client.post(url, body, headers) do
      {:ok, response} ->
        Logger.debug("Response: #{inspect(response)}")
        build_insert_response(response, returning)

      {:error, reason} ->
        Logger.error("Failed request: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @spec prepare_insert_request(schema_meta, fields, returning) :: {String.t, String.t, HTTPoison.headers}
  defp prepare_insert_request(schema_meta, fields, returning) do
    %{service_url: service_url} = Exoda.ServiceDescription.get_settings()
    {_, source_path} = schema_meta.source
    url = "#{service_url}/#{source_path}"

    {:ok, body} = build_body(fields)

    return_preference = if Enum.empty?(returning), do: "minimal", else: "representation"
    headers = [
      {"Prefer", "return=#{return_preference}"},
      {"Content-Type", "application/json"},
      {"Accept", "application/json"}
    ]

    {url, body, headers}
  end

  @spec build_body(fields) :: String.t()
  defp build_body(fields) do
    fields
    |> Enum.reduce(%{}, fn {name, value}, acc -> Map.put(acc, name, value) end)
    |> Jason.encode()
  end

  @spec build_insert_response(HTTPoison.Response.t(), returning) ::
          {:ok, fields} | {:error, any} | {:invalid, constraints} | no_return
  defp build_insert_response(%HTTPoison.Response{body: body, status_code: 201}, returning) do
    parsed = Jason.decode!(body)

    fields =
      returning
      |> Enum.map(fn name ->
        case Map.fetch(parsed, name) do
          {:ok, value} -> {name, value}
          :error -> nil
        end
      end)
      |> Enum.reject(&(&1 == nil))

    {:ok, fields}
  end

  defp build_insert_response(%HTTPoison.Response{status_code: 204}, _returning) do
    {:ok, []}
  end

  defp build_insert_response(
         %HTTPoison.Response{body: body, status_code: status_code},
         _returning
       ) do
    # TODO: parse constraints?
    {:error,
     "Error inserting to remote OData server.\nStatus code: #{status_code}.\nResponse body: #{
       body
     }"}
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
