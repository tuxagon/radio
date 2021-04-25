defmodule Radio.StationRegistryTest do
  use ExUnit.Case, async: true
  doctest Radio.StationRegistry

  import Mox

  @station_name "test"
  @track_id "4cOdK2wGLETKBW3PvgPWqT"
  @track_info %Radio.Spotify.TrackInfo{
    artist_names: ["Rick Astley"],
    duration_ms: 213_573,
    name: "Never Gonna Give You Up",
    uri: "spotify:track:4cOdK2wGLETKBW3PvgPWqT"
  }

  setup :verify_on_exit!

  setup do
    child_spec = %{
      id: StationRegistryTest,
      start: {Radio.StationRegistry, :start_link, [[name: StationRegistryTest]]}
    }

    server_pid = start_supervised!(child_spec)
    %{server: server_pid}
  end

  test "ensures a station exists and returns it", %{server: pid} do
    {:ok, station_pid} = Radio.StationRegistry.lookup(pid, @station_name)
    assert is_pid(station_pid)

    queue = Radio.StationRegistry.upcoming(pid, @station_name)
    assert [] == queue
  end

  test "adds a track to the station queue", %{server: pid} do
    {:ok, station_pid} = Radio.StationRegistry.lookup(pid, @station_name)

    parent = self()
    ref = make_ref()

    allow(Radio.Spotify.MockApiClient, self(), station_pid)

    expect(Radio.Spotify.MockApiClient, :get_track, fn _track_id ->
      send(parent, {ref, :get_track})
      {:ok, @track_info}
    end)

    Radio.StationRegistry.queue_track(pid, @station_name, @track_id)
    assert_receive {^ref, :get_track}

    queue = Radio.StationRegistry.upcoming(pid, @station_name)
    assert [@track_info] == queue
  end
end
