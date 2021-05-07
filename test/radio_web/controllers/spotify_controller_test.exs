defmodule RadioWeb.SpotifyControllerTest do
  use RadioWeb.ConnCase
  doctest RadioWeb.SpotifyController

  describe "index" do
    test "renders html", %{conn: conn} do
      conn = get(conn, Routes.spotify_path(conn, :index))

      assert html_response(conn, 200) =~ "Login with Spotify"
    end
  end

  describe "choose" do
    test "renders html", %{conn: conn} do
      conn = get(conn, Routes.spotify_path(conn, :choose))

      assert html_response(conn, 200) =~ "Station name"
    end

    test "redirects to station when provided one", %{conn: conn} do
      station_name = "test"

      conn = get(conn, Routes.spotify_path(conn, :choose, return_station: station_name))

      assert redirected_to(conn) == Routes.station_path(conn, :index, station_name)
    end
  end

  describe "login" do
    def use_correct_auth_state(conn, expected_url) do
      case Enum.filter(conn.resp_headers, fn {header, _value} -> header == "location" end) do
        [{"location", actual_url}] ->
          expected_uri = URI.parse(expected_url)
          actual_uri = URI.parse(actual_url)
          %{"state" => actual_state} = URI.decode_query(actual_uri.query)

          expected_query =
            expected_uri.query
            |> URI.decode_query()
            |> Map.put("state", actual_state)
            |> URI.encode_query()

          url = expected_uri |> Map.put(:query, expected_query) |> URI.to_string()

          {url, actual_state}

        _ ->
          flunk()
      end
    end

    test "redirects to authorize url with correct query params", %{conn: conn} do
      {url, _state} = Radio.Spotify.authorize_url()

      conn = get(conn, Routes.spotify_path(conn, :login))

      {expected_url, actual_state} = use_correct_auth_state(conn, url)

      assert redirected_to(conn) == expected_url
      assert actual_state == get_session(conn, :spotify_auth_state)
      assert "" == get_session(conn, :station)
    end

    test "places station in session when return station is given", %{conn: conn} do
      station_name = "test"
      {url, _state} = Radio.Spotify.authorize_url()

      conn = get(conn, Routes.spotify_path(conn, :login, return_station: station_name))

      {expected_url, actual_state} = use_correct_auth_state(conn, url)

      assert redirected_to(conn) == expected_url
      assert actual_state == get_session(conn, :spotify_auth_state)
      assert station_name == get_session(conn, :station)
    end
  end

  # describe "play" do
  #   test "plays music on the specified device", %{conn: conn} do
  #     device_id = "123"
  #     station_name = "test"
  #     token_info = %Radio.Spotify.TokenInfo{access_token: "abc123"}

  #     parent = self()
  #     ref = make_ref()

  #     {:ok, station_pid} = Radio.StationRegistry.lookup(station_name)

  #     allow(Radio.Spotify.MockApiClient, self(), station_pid)

  #     expect(Radio.Spotify.MockApiClient, :start_playback, fn _token_info, _device_id, _uris ->
  #       send(parent, {ref, :start_playback})
  #       {:ok, nil}
  #     end)

  #     conn =
  #       conn
  #       |> put_session(:token_info, token_info)
  #       |> post(Routes.spotify_path(RadioWeb.Endpoint, :play, device_id), %{
  #         station_name: station_name
  #       })

  #     assert_receive {^ref, :start_playback}
  #     assert json_response(conn, 200)["device_id"] == device_id
  #     verify!()
  #   end
  # end
end
