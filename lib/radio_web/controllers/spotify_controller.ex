defmodule RadioWeb.SpotifyController do
  use RadioWeb, :controller

  alias Radio.Spotify
  alias Radio.Spotify.User

  defp spotify_api_client, do: Application.get_env(:radio, :spotify_api_client)

  def index(conn, _params) do
    conn |> render("index.html")
  end

  def login(conn, params) do
    {authorize_url, auth_state} = Spotify.authorize_url()

    station = params["return_station"] || ""

    conn
    |> put_session(:spotify_auth_state, auth_state)
    |> put_session(:station, station)
    |> redirect(external: authorize_url)
  end

  def callback(conn, %{"state" => state, "code" => code}) do
    stored_state = get_session(conn, :spotify_auth_state)
    station = get_session(conn, :station)

    if state != stored_state do
      redirect(conn, to: Routes.spotify_path(conn, :index, error: "state_mismatch"))
    else
      conn = clear_session(conn)

      with {:ok, %{"access_token" => access_token}} <-
             spotify_api_client().exchange_auth_code_for_token(code),
           {:ok, %User{} = user} <- spotify_api_client().get_my_user(access_token),
           {:ok, context} <- Radio.ContextCache.get(user.id) do
        Radio.ContextCache.put(user.id, %Radio.Context{
          user: user,
          access_token: access_token,
          selected_device: if(is_nil(context), do: nil, else: context.selected_device)
        })

        conn
        |> put_session(:current_user_id, user.id)
        |> redirect(
          to:
            if(to_string(station) == "",
              do: Routes.spotify_path(conn, :choose),
              else: Routes.station_path(conn, :index, station)
            )
        )
      else
        _ ->
          redirect(conn, to: Routes.spotify_path(conn, :index, error: "invalid_code"))
      end
    end
  end

  def choose(conn, params) do
    case params do
      %{"return_station" => station_name} ->
        conn |> redirect(to: Routes.station_path(conn, :index, station_name))

      _params ->
        conn |> render("choose.html")
    end
  end

  def logout(conn, _params) do
    user_id = get_session(conn, :current_user_id)

    Radio.ContextCache.del(user_id)

    conn |> redirect(to: "/")
  end
end
