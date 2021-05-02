# In this file, we load production configuration and secrets
# from environment variables. You can also hardcode secrets,
# although such is generally not recommended and you have to
# remember to add this file to your .gitignore.
import Config

database_url =
  System.get_env("DATABASE_URL") ||
    raise("expected the DATABASE_URL environment variable to be set")

config :radio, Radio.Repo,
  # ssl: true,
  url: database_url,
  load_from_system_env: true,
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

config :radio, RadioWeb.Endpoint,
  load_from_system_env: true,
  http: [
    port: String.to_integer(System.get_env("PORT") || "4000"),
    transport_options: [socket_opts: [:inet6]]
  ],
  server: true

spotify_redirect_uri =
  System.get_env("SPOTIFY_REDIRECT_URI") ||
    raise """
    environment variable SPOTIFY_REDIRECT_URI is missing.
    You can set it here: https://developer.spotify.com/dashboard/applications
    """

spotify_client_id =
  System.get_env("SPOTIFY_CLIENT_ID") ||
    raise """
    environment variable SPOTIFY_CLIENT_ID is missing.
    You can get it here: https://developer.spotify.com/dashboard/applications
    """

spotify_client_secret =
  System.get_env("SPOTIFY_CLIENT_SECRET") ||
    raise """
    environment variable SPOTIFY_CLIENT_SECRET is missing.
    You can get it here: https://developer.spotify.com/dashboard/applications
    """

config :radio, :spotify,
  redirect_uri: spotify_redirect_uri,
  client_id: spotify_client_id,
  client_secret: spotify_client_secret

# ## Using releases (Elixir v1.9+)
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start each relevant endpoint:
#
#     config :radio, RadioWeb.Endpoint, server: true
#
# Then you can assemble a release by calling `mix release`.
# See `mix help release` for more information.
