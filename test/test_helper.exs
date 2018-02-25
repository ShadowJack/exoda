ExUnit.start()

# Define mocks
Mox.defmock(Exoda.ClientMock, for: Exoda.Client)
Mox.defmock(Exoda.RepoMock, for: Ecto.Repo)
