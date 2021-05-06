use Mix.Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :radio, Radio.Repo,
  username: "postgres",
  password: "postgres",
  database: "radio_test",
  pool: Ecto.Adapters.SQL.Sandbox

if System.get_env("GITHUB_ACTIONS") do
  config :radio, Radio.Repo,
    username: "postgres",
    password: "postgres"
end

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :radio, RadioWeb.Endpoint,
  http: [port: 4002],
  server: false

config :radio,
  http_client: Radio.HTTPClientMock,
  spotify_api_client: Radio.Spotify.MockApiClient

# Print only warnings and errors during test
config :logger, level: :warn
