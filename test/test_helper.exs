ExUnit.start()

# Define mocks
Mox.defmock(Exoda.RepoMock, for: Ecto.Repo)
