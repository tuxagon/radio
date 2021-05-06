defmodule RadioWeb.SpotifyControllerTest do
  use RadioWeb.ConnCase
  doctest RadioWeb.SpotifyController

  import Mox

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
