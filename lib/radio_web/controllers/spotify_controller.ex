defmodule RadioWeb.SpotifyController do
  use RadioWeb, :controller

  alias Radio.Spotify

  def login(conn, _params) do
    %{url: authorize_url, state: auth_state} = Spotify.authorize_url()

    conn
    |> put_session(:spotify_auth_state, auth_state)
    |> redirect(external: authorize_url)
  end

  def callback(conn, %{"state" => state, "code" => code}) do
    stored_state = get_session(conn, :spotify_auth_state)

    if state != stored_state do
      redirect(conn, to: "/?error=state_mismatch")
    else
      clear_session(conn)

      case Spotify.get_token_from_authorization_code(code) do
        {:ok, %{access_token: access_token, refresh_token: refresh_token}} ->
          conn
          |> put_session(:access_token, access_token)
          |> put_session(:refresh_token, refresh_token)
          |> redirect(to: "/")

        {:error, _reason} ->
          redirect(conn, to: "/?error=invalid_token")
      end
    end
  end
end
