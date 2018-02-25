use Mix.Config

config :exoda, :client, Exoda.Fakes.Client

# Configure mock repo
config :exoda, Exoda.RepoMock,
  adapter: Exoda,
  url: "http://services.odata.org/V4/(S(1ldwlff3vlwnnll4udpfi4uj))/OData/OData.svc"
