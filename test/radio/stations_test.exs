defmodule Radio.StationsTest do
  use ExUnit.Case, async: true

  import Mox

  # @station_name "test"

  @track_uri "spotify:track:4cOdK2wGLETKBW3PvgPWqT"
  @song_link "https://open.spotify.com/track/4cOdK2wGLETKBW3PvgPWqT?si=8e1485e9ca264fbf"
  @track_id "4cOdK2wGLETKBW3PvgPWqT"
  @track_info %Radio.Spotify.TrackInfo{
    duration_ms: 213_573,
    name: "Never Gonna Give You Up",
    uri: @track_uri,
    artist_names: ["Rick Astley"],
    album: %Radio.Spotify.Album{
      image_url: "https://i.scdn.co/image/ab67616d0000b2735755e164993798e0c9ef7d7a",
      name: "Whenever You Need Somebody"
    }
  }

  describe "find_tracks_by" do
    test "returns empty list for error" do
      expect(Radio.Spotify.MockApiClient, :search_tracks, fn _search, _limit, _offset ->
        {:error, %{message: "No search query", status: 400}}
      end)

      tracks = Radio.Stations.find_tracks_by("")

      assert [] == tracks
    end

    test "returns a singleton list for spotify uri" do
      expect(Radio.Spotify.MockApiClient, :get_track, fn @track_id ->
        {:ok, @track_info}
      end)

      tracks = Radio.Stations.find_tracks_by(@track_uri)

      assert [@track_info] == tracks
    end

    test "returns a singleton list for spotify song link" do
      expect(Radio.Spotify.MockApiClient, :get_track, fn @track_id ->
        {:ok, @track_info}
      end)

      tracks = Radio.Stations.find_tracks_by(@song_link)

      assert [@track_info] == tracks
    end

    test "returns a list of results for a search term" do
      expect(Radio.Spotify.MockApiClient, :search_tracks, fn _search, _limit, _offset ->
        {:ok, [@track_info]}
      end)

      tracks = Radio.Stations.find_tracks_by("Never Gonna Give You Up")

      assert [@track_info] == tracks
    end
  end

  # describe "queue_track" do
  #   test "adds track to the station queue" do
  #     child_spec = %{
  #       id: TrackQueueTest,
  #       start: {Radio.TrackQueue, :start_link, [@station_name, [name: TrackQueueTest]]}
  #     }

  #     server_pid = start_supervised!(child_spec)

  #     allow(Radio.Spotify.MockApiClient, self(), server_pid)

  #     parent = self()
  #     ref = make_ref()

  #     expect(Radio.Spotify.MockApiClient, :get_track, fn @track_id ->
  #       {:ok, @track_info}
  #     end)

  #     Radio.Stations.queue_track(@station_name, @track_uri)

  #     queue = Radio.StationRegistry.upcoming(@station_name)
  #     assert [@track_info] == queue
  #   end
  # end
end
