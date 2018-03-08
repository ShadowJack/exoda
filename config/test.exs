use Mix.Config

config :exoda, :client, Exoda.Fakes.Client

# Configure fake repo
config :exoda, Exoda.Fakes.Repo,
  adapter: Exoda,
  url: "http://services.odata.org/V4/(S(1ldwlff3vlwnnll4udpfi4uj))/OData/OData.svc"
