ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Radio.Repo, :manual)

Mox.defmock(Radio.Spotify.MockApiClient, for: Radio.Spotify.ApiClientBehaviour)
