defmodule RadioWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :radio

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_radio_key",
    signing_salt: "Wa8rz1A7"
  ]

  socket "/socket", RadioWeb.UserSocket,
    websocket: true,
    longpoll: false

  socket "/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]]

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :radio,
    gzip: false,
    only: ~w(css fonts images js favicon.ico robots.txt)

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :radio
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug RadioWeb.Router

  def init(_key, config) do
    if config[:load_from_system_env] do
      port =
        System.get_env("PORT") ||
          raise("expected the PORT environment variable to be set")

      secret_key_base =
        System.get_env("SECRET_KEY_BASE") ||
          raise("expected the SECRET_KEY_BASE environment variable to be set")

      host =
        System.get_env("APP_NAME") ||
          raise("expected the APP_NAME environment variable to be set")

      signing_salt =
        System.get_env("LIVE_VIEW_SIGNING_SALT") ||
          raise("expected the LIVE_VIEW_SIGNING_SALT environment variable to be set")

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

      config =
        config
        |> Keyword.put(:http, [:inet6, port: port])
        |> Keyword.put(:secret_key_base, secret_key_base)
        |> Keyword.put(:live_view, signing_salt: signing_salt)
        |> Keyword.put(:url, host: host <> ".gigalixirapp.com", port: port)
        |> Keyword.put(:spotify,
          redirect_uri: spotify_redirect_uri,
          client_id: spotify_client_id,
          client_secret: spotify_client_secret
        )

      {:ok, config}
    else
      {:ok, config}
    end
  end
end
