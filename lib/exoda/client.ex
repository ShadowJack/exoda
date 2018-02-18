defmodule Exoda.Client do
  use Agent
  require Logger
  import SweetXml

  @moduledoc """
  This module should be used to make http requests to the remote OData server.
  """

  @typep repo :: Ecto.Repo.t()
  @typep options :: Keyword.t()

  ##
  # Public API
  #

  @doc """
  Provide Genserver.Spec.worker description so that external supervisor
  would know how to run the Exoda.Client process.
  It's called from `Ecto.Repo.Supervisor.init/2`
  """
  @spec child_spec(repo, options) :: Supervisor.Spec.child_spec
  def child_spec(_repo, opts) do
    Supervisor.Spec.worker(Exoda.Client, [opts])
  end

  @doc """
  Send a POST request to the remote OData server
  """
  @spec post(String.t, any, HTTPoison.headers, Keyword.t) :: {:ok, HTTPoison.Response.t} | {:error, HTTPoison.Error.t}
  def post(url, body, headers \\ [], opts \\ []) do
    service_url = Agent.get(__MODULE__, fn %{service_url: service_url} -> service_url end)
    HTTPoison.post("#{service_url}/#{url}", body, headers, opts)
  end

  @doc """
  Read settings of the adapter
  """
  @spec get_settings() :: Map.t
  def get_settings() do
    Agent.get(__MODULE__, fn state -> state end)
  end

  ##
  # GenServer implementation
  #

  @doc false
  @spec start_link(options) :: Agent.on_start
  def start_link(opts) do
    Agent.start_link(fn -> 
      {:ok, state} = init(opts) 
      state
    end, name: __MODULE__)
  end

  @doc false
  @spec init(options) :: {:ok, term}
  def init(opts) do
    Logger.info(inspect(opts))
    with {:ok, repo} <- Keyword.fetch(opts, :repo),
         {:ok, app} <- Keyword.fetch(opts, :otp_app),
         config when config != nil <- Application.get_env(app, repo),
         {:ok, service_url} <- Keyword.fetch(config, :url), 
         {:ok, %{meta_url: meta_url, odata_version: odata_version}} <- fetch_service_info(service_url),
         {:ok, %{namespace: namespace}} <- fetch_metadata(meta_url) do
           {:ok, %{
             repo: repo, 
             app: app,
             service_url: service_url,
             odata_version: odata_version,
             namespace: namespace 
           }}
    else
      nil -> raise "Configuration of Ecto repo is not found"
      :error -> raise ArgumentError, "Wrong configuration of Ecto repo"
      {:error, reason} -> raise reason
    end
  end

  @spec fetch_service_info(String.t) :: {:ok, Map.t} | {:error, String.t}
  defp fetch_service_info(service_url) do
    response = HTTPoison.get!(service_url, [{"Accept", "application/json"}], follow_redirect: true)
    if response.status_code != 200 do
      {:error, "Ecto configuration error: service url #{service_url} is not accessible. Status code: #{response.status_code}"}
    else
      with {:ok, odata_version} <- extract_odata_verison(response),
           {:ok, meta_url} <- extract_meta_url(response) do
        Logger.info("OData service #{service_url} has version #{odata_version}")
        Logger.info("OData service #{service_url} has metadata info at #{meta_url}")
        {:ok, %{odata_version: odata_version, meta_url: meta_url}}
      else
        {:error, reason} -> {:error, reason}
      end
    end
  end

  @spec extract_odata_verison(HTTPoison.Response.t) :: {:ok, String.t} | {:error, String.t}
  defp extract_odata_verison(%HTTPoison.Response{headers: headers, request_url: service_url}) do
    version_header = Enum.find(headers, fn {name, _} -> name == "OData-Version" end)
    case version_header do
      {_name, "4" <> _ = version} -> 
        {:ok, version}
      {_name, version} -> 
        {:error,  "OData service #{service_url} has unsupported version: #{version}. Only OData v4 is supported by Exoda adapter."}
      nil -> 
        {:error, "Version info is not provided by OData service #{service_url}. Only OData v4 is supported by Exoda adapter."}
    end
  end

  @spec extract_meta_url(HTTPoison.Response.t) :: {:ok, String.t}
  defp extract_meta_url(%HTTPoison.Response{body: body}) do
    %{"@odata.context" => meta_url} = Jason.decode!(body)
    {:ok, meta_url}
  end

  @spec fetch_metadata(String.t) :: {:ok, Map.t} | {:error, String.t}
  defp fetch_metadata(meta_url) do
    response = HTTPoison.get!(meta_url, [{"Accept", "application/xml"}], follow_redirect: true)
    parse_metadata_response(response)
  end

  @spec parse_metadata_response(HTTPoison.Response.t) :: {:ok, map} | {:error, String.t}
  defp parse_metadata_response(%HTTPoison.Response{status_code: 200, body: body}) do
    namespace = body |> xpath(~x"//Schema/@Namespace") |> to_string()
    {:ok, %{namespace: namespace}}
  end
  defp parse_metadata_response(%HTTPoison.Response{status_code: status_code, request_url: request_url, body: body}) do
    {:error, "Error while getting metadata of OData service at #{request_url}. Status code: #{status_code}. Body: #{body}"}
  end
end
