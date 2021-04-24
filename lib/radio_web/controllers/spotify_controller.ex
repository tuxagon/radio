defmodule RadioWeb.SpotifyController do
  use RadioWeb, :controller

  alias Radio.SpotifyApi

  def login(conn, _params) do
    %{url: authorize_url, state: auth_state} = SpotifyApi.authorize_url()

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

      case SpotifyApi.get_token_from_authorization_code(code) do
        {:ok, %Radio.TokenInfo{} = token_info} ->
          IO.puts(token_info.access_token)

          {:ok, user} = SpotifyApi.user_profile(token_info)

          conn
          |> put_session(:token_info, token_info)
          |> put_session(:spotify_user, user)
          # TODO replace with something dynamic
          |> redirect(to: "/radio/test")

        {:error, _reason} ->
          redirect(conn, to: "/?error=invalid_token")
      end
    end
  end
end
