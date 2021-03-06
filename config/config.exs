# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :radio,
  ecto_repos: [Radio.Repo],
  http_client: HTTPoison,
  spotify_api_client: Radio.Spotify.ApiClient

# Configures the endpoint
config :radio, RadioWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "queEUbKeyceMFkOfx8YZ4y3RhGFi75Z7m18yyyKjADMx7pRXexgZNMuRJKyPffvI",
  render_errors: [view: RadioWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Radio.PubSub,
  live_view: [signing_salt: "NE4Oq6Bq"]

config :radio, :spotify,
  api_url: "https://api.spotify.com",
  authorize_url: "https://accounts.spotify.com/authorize",
  redirect_uri: "http://localhost:4000/callback",
  token_url: "https://accounts.spotify.com/api/token"

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
