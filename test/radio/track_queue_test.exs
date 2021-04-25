defmodule Radio.TrackQueueTest do
  use ExUnit.Case, async: true
  doctest Radio.TrackQueue

  import Mox

  @track_id "4cOdK2wGLETKBW3PvgPWqT"
  @track_info %Radio.Spotify.TrackInfo{
    artist_names: ["Rick Astley"],
    duration_ms: 213_573,
    name: "Never Gonna Give You Up",
    uri: "spotify:track:4cOdK2wGLETKBW3PvgPWqT"
  }

  setup :verify_on_exit!

  setup do
    server_pid = start_supervised!(Radio.TrackQueue)

    allow(Radio.Spotify.MockApiClient, self(), server_pid)

    %{server: server_pid}
  end

  test "gets current track queue", %{server: pid} do
    queue = Radio.TrackQueue.current_queue(pid)
    assert [] == queue
  end

  test "adds track to queue when api finds info", %{server: pid} do
    parent = self()
    ref = make_ref()

    expect(Radio.Spotify.MockApiClient, :get_track, fn _track_id ->
      send(parent, {ref, :get_track})
      {:ok, @track_info}
    end)

    Radio.TrackQueue.add_track(pid, @track_id)
    assert_receive {^ref, :get_track}

    queue = Radio.TrackQueue.current_queue(pid)
    assert [@track_info] == queue
  end

  test "does not add track when api has error", %{server: pid} do
    parent = self()
    ref = make_ref()

    expect(Radio.Spotify.MockApiClient, :get_track, fn _track_id ->
      send(parent, {ref, :get_track})
      {:error, "not found"}
    end)

    Radio.TrackQueue.add_track(pid, @track_id)
    assert_receive {^ref, :get_track}

    queue = Radio.TrackQueue.current_queue(pid)
    assert [] == queue
  end

  test "schedules for the song to leave the queue", %{server: pid} do
    parent = self()
    ref = make_ref()
    track_info = Map.merge(@track_info, %{duration_ms: 100})

    expect(Radio.Spotify.MockApiClient, :get_track, fn _track_id ->
      send(parent, {ref, :get_track})
      Process.send_after(parent, :removed, track_info.duration_ms)
      {:ok, track_info}
    end)

    Radio.TrackQueue.add_track(pid, @track_id)
    assert_receive {^ref, :get_track}, 100

    queue = Radio.TrackQueue.current_queue(pid)
    assert [track_info] == queue

    receive do
      :removed ->
        queue = Radio.TrackQueue.current_queue(pid)
        assert [] == queue
    after
      200 -> flunk("queue removal never happened")
    end
  end
end
