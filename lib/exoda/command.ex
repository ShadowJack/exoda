defmodule Exoda.Command do
  require Logger
  alias HTTPoison.Response

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
    Logger.debug(
      """
      repo: #{inspect(repo)}, 
      meta: #{inspect(schema_meta)},
      fields: #{inspect(fields)},
      returning: #{inspect(returning)},
      opts: #{inspect(opts)}
      """
    )

    with {:ok, url} <- build_insert_url(schema_meta),
         {:ok, body} <- build_body(fields),
         {:ok, headers} <- build_headers(returning),
         {:ok, response} <- @client.post(url, body, headers) do
      Logger.debug("Response: #{inspect(response)}")
      parse_response(response, returning)
    else
      {:error, reason} ->
        Logger.error("Failed request: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @spec build_insert_url(schema_meta) :: {:ok, String.t}
  def build_insert_url(schema_meta) do
    %{service_url: service_url} = Exoda.ServiceDescription.get_settings()
    {_, source_path} = schema_meta.source
    {:ok, "#{service_url}/#{source_path}"}
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
          schema_meta,
          fields,
          filters,
          returning,
          options
        ) ::
          {:ok, fields}
          | {:invalid, constraints}
          | {:error, :stale}
          | no_return
  def update(_repo, schema_meta, fields, filters, returning, _opts) do
    Logger.debug("Fields: #{inspect(fields)}, filters: #{inspect(filters)}, schema_meta: #{inspect(schema_meta)}")
    
    with {:ok, url} <- build_update_url(schema_meta, filters),
         {:ok, body} <- build_body(fields),
         {:ok, headers} <- build_headers(returning),
         {:ok, response} <- @client.patch(url, body, headers) do
      parse_response(response, returning)
    else
      {:error, reason} -> 
        Logger.error("Error updating entry: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @spec build_update_url(schema_meta, filters) :: {:ok, String.t} | {:error, :stale}
  defp build_update_url(schema_meta, filters) do
    case get_primary_key(schema_meta, filters) do
      {_, nil} -> 
        {:error, :stale}

      {pk_type, pk_value} ->
        %{service_url: service_url} = Exoda.ServiceDescription.get_settings()
        {_, source_path} = schema_meta.source
        unquoted_types = [:id, :integer, :boolean]
        if Enum.any?(unquoted_types, &(&1 == pk_type)) do
          {:ok, "#{service_url}/#{source_path}(#{pk_value})"}
        else
          {:ok, "#{service_url}/#{source_path}('#{pk_value}')"}
        end
    end
  end

  @spec get_primary_key(schema_meta, filters) :: {atom, any}
  defp get_primary_key(schema_meta, filters) do
    primary_keys = schema_meta.schema.__schema__(:primary_key)
    if length(primary_keys) != 1 do
      raise ArgumentError,
      """
      Only entities with single primary key are supported.
      Entity with #{length(primary_keys)} primary keys is passed: #{inspect(primary_keys)}
      """
    end

    pk_source = schema_meta.schema.__schema__(:field_source, hd(primary_keys))
    pk_type = schema_meta.schema.__schema__(:type, hd(primary_keys))
    pk_value = 
      filters 
      |> Enum.find_value(fn {name, value} -> 
        if name == pk_source, do: value, else: nil 
      end)
    {pk_type, pk_value}
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


  ## Private
  #
  @spec build_headers(returning) :: {:ok, HTTPoison.headers}
  defp build_headers(returning) do
    return_preference = if returning == [], do: "minimal", else: "representation"
    headers = [
      {"Prefer", "return=#{return_preference}"},
      {"Content-Type", "application/json"},
      {"Accept", "application/json"}
    ]
    {:ok, headers}
  end

  @spec build_body(fields) :: {:ok, String.t} | {:error, Jason.EncodeError.t}
  defp build_body(fields) do
    fields
    |> Enum.reduce(%{}, fn {name, value}, acc -> Map.put(acc, name, value) end)
    |> Jason.encode()
  end

  @spec parse_response(Response.t, returning) ::
          {:ok, fields} | {:error, any} | {:invalid, constraints} | no_return
  defp parse_response(%Response{body: body, status_code: status_code}, returning) when status_code == 200 or status_code == 201 do
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
  defp parse_response(%Response{status_code: 204}, _) do
    {:ok, []}
  end
  defp parse_response(%Response{body: body, status_code: status_code}, _) do
   {
     :error,
      """
      Error requesting remote OData server.
      Status code: #{status_code}.
      Response body: #{body}.
      """
    }
  end
end
