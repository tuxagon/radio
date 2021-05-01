defmodule RadioWeb.SpotifyController do
  use RadioWeb, :controller

  alias Radio.Spotify
  alias Radio.Spotify.TokenInfo
  alias Radio.Spotify.User
  alias Radio.UserContext

  @spec api_client() :: module()
  def api_client, do: Application.get_env(:radio, :spotify_api)

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
      conn = clear_session(conn)

      with {:ok, %{"access_token" => access_token}} <-
             api_client().exchange_auth_code_for_token(code),
           {:ok, %User{} = user} <- api_client().get_my_user(access_token),
           context <- UserContext.get(Radio.UserContext, user.id) do
        UserContext.insert(Radio.UserContext, %Radio.Context{
          user: user,
          access_token: access_token,
          selected_device: if(is_nil(context), do: nil, else: context.selected_device)
        })

        conn
        |> put_session(:current_user_id, user.id)
        # TODO replace with something dynamic
        |> redirect(to: "/radio/test")
      else
        _ ->
          redirect(conn, to: "/?error=invalid_token")
      end
    end
  end

  def token(conn, _params) do
    case get_session(conn, :token_info) do
      %TokenInfo{access_token: access_token} ->
        json(conn, access_token)

      _ ->
        conn |> put_status(:not_found)
    end
  end

  def refresh(conn, _params) do
    text(conn, "todo")
  end

  def play(conn, %{"device_id" => device_id, "station_name" => station_name} = _params) do
    user_id = get_session(conn, :current_user_id)

    context = UserContext.get(Radio.UserContext, user_id)

    {:ok, station} = Radio.StationRegistry.lookup(station_name)

    conn
    |> json(%{device_id: device_id})
    |> handle_result(Radio.TrackQueue.play_on(station, device_id, context.access_token))
  end

  defp handle_result(conn, result) do
    case result do
      {:ok, _body} ->
        conn

      {:error, %{status: 401}} ->
        conn |> redirect(to: "/login") |> put_status(:unauthorized)

      {:error, _reason} ->
        conn |> put_status(:failed_dependency)
    end
  end
end
