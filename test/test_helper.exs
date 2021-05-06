ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Radio.Repo, :manual)

Mox.defmock(Radio.HTTPClientMock, for: HTTPoison.Base)
Mox.defmock(Radio.Spotify.MockApiClient, for: Radio.Spotify.ApiBehaviour)
