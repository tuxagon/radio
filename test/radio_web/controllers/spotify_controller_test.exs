defmodule RadioWeb.SpotifyControllerTest do
  use RadioWeb.ConnCase
  doctest RadioWeb.SpotifyController

  import Mox

  @auth_code "test_code"
  @exchange_auth_code_for_token_resp %{
    "access_token" => "c28ab7e3-bfc8-42b5-bfaf-8d32353a6e57",
    "expires_in" => 3600,
    "refresh_token" => "39ebc2ef-0b90-4a07-bf18-0af03fd5fb09",
    "scope" => "user-read-email",
    "token_type" => "Bearer"
  }
  @user %Radio.Spotify.User{id: "37b660b8-7525-4904-905a-e0fd09965603", name: "Test User"}

  setup :verify_on_exit!

  setup do
    Cachex.clear!(:context_cache)
    :ok
  end

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

  describe "callback" do
    test "redirects with state_mismatch when auth state does not match", %{conn: conn} do
      bad_state = "invalid"

      {_, actual_state} = Radio.Spotify.authorize_url()

      conn =
        conn
        |> put_session(:spotify_state, actual_state)
        |> get(Routes.spotify_path(conn, :callback, state: bad_state, code: @auth_code))

      assert redirected_to(conn) == Routes.spotify_path(conn, :index, error: "state_mismatch")
    end

    test "redirects with invalid_code when auth code does not match", %{conn: conn} do
      {_, actual_state} = Radio.Spotify.authorize_url()

      expect(Radio.Spotify.MockApiClient, :exchange_auth_code_for_token, fn _code ->
        {:error, %{message: "Invalid authorization code", status: 400}}
      end)

      conn =
        conn
        |> put_session(:spotify_auth_state, actual_state)
        |> get(Routes.spotify_path(conn, :callback, state: actual_state, code: @auth_code))

      assert redirected_to(conn) == Routes.spotify_path(conn, :index, error: "invalid_code")
      assert %{} = get_session(conn)
    end

    test "exchanges code for token and redirects to station selection", %{conn: conn} do
      {_, actual_state} = Radio.Spotify.authorize_url()

      access_token = @exchange_auth_code_for_token_resp["access_token"]

      expect(Radio.Spotify.MockApiClient, :exchange_auth_code_for_token, fn @auth_code ->
        {:ok, @exchange_auth_code_for_token_resp}
      end)

      expect(Radio.Spotify.MockApiClient, :get_my_user, fn ^access_token ->
        {:ok, @user}
      end)

      conn =
        conn
        |> put_session(:spotify_auth_state, actual_state)
        |> get(Routes.spotify_path(conn, :callback, state: actual_state, code: @auth_code))

      assert redirected_to(conn) == Routes.spotify_path(conn, :choose)
      assert nil == get_session(conn, :spotify_auth_state)
      assert @user.id == get_session(conn, :current_user_id)

      assert {:ok, %Radio.Context{user: @user, access_token: access_token, selected_device: nil}} ==
               Radio.ContextCache.get(@user.id)
    end

    test "exchanges code for token and redirects to a pre-determined station", %{conn: conn} do
      {_, actual_state} = Radio.Spotify.authorize_url()

      station = "test"
      access_token = @exchange_auth_code_for_token_resp["access_token"]

      expect(Radio.Spotify.MockApiClient, :exchange_auth_code_for_token, fn @auth_code ->
        {:ok, @exchange_auth_code_for_token_resp}
      end)

      expect(Radio.Spotify.MockApiClient, :get_my_user, fn ^access_token ->
        {:ok, @user}
      end)

      conn =
        conn
        |> put_session(:spotify_auth_state, actual_state)
        |> put_session(:station, station)
        |> get(Routes.spotify_path(conn, :callback, state: actual_state, code: @auth_code))

      assert redirected_to(conn) == Routes.station_path(conn, :index, station)
      assert nil == get_session(conn, :spotify_auth_state)
      assert nil == get_session(conn, :station)
      assert @user.id == get_session(conn, :current_user_id)

      assert {:ok, %Radio.Context{user: @user, access_token: access_token, selected_device: nil}} ==
               Radio.ContextCache.get(@user.id)
    end

    test "exchanges code for token and keeps existing selected device", %{conn: conn} do
      {_, actual_state} = Radio.Spotify.authorize_url()

      station = "test"
      access_token = @exchange_auth_code_for_token_resp["access_token"]

      existing_context = %Radio.Context{
        user: @user,
        access_token: access_token,
        selected_device: %Radio.Spotify.Device{
          id: "40c4c27b-38d5-4779-bcac-80b62183d135",
          name: "Test Device",
          type: "Computer"
        }
      }

      Radio.ContextCache.put(@user.id, existing_context)

      expect(Radio.Spotify.MockApiClient, :exchange_auth_code_for_token, fn @auth_code ->
        {:ok, @exchange_auth_code_for_token_resp}
      end)

      expect(Radio.Spotify.MockApiClient, :get_my_user, fn ^access_token ->
        {:ok, @user}
      end)

      conn =
        conn
        |> put_session(:spotify_auth_state, actual_state)
        |> put_session(:station, station)
        |> get(Routes.spotify_path(conn, :callback, state: actual_state, code: @auth_code))

      assert redirected_to(conn) == Routes.station_path(conn, :index, station)
      assert nil == get_session(conn, :spotify_auth_state)
      assert nil == get_session(conn, :station)
      assert @user.id == get_session(conn, :current_user_id)

      assert {:ok, existing_context} == Radio.ContextCache.get(@user.id)
    end
  end
end
