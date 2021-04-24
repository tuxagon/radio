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

          # refresh_duration_ms = div(token_info.expires_in, 2) * 1000
          # Process.send_after(Radio.TokenStore, {:refresh, token_info}, refresh_duration_ms)

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

  def token(conn, _params) do
    case get_session(conn, :token_info) do
      %Radio.TokenInfo{access_token: access_token} ->
        json(conn, access_token)

      _ ->
        conn |> put_status(:not_found)
    end
  end

  def refresh(conn, _params) do
    text(conn, "todo")
  end
end
