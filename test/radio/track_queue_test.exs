defmodule Radio.TrackQueueTest do
  use ExUnit.Case, async: true
  doctest Radio.TrackQueue

  import Mox

  @station_name "test"

  @track_id "4cOdK2wGLETKBW3PvgPWqT"
  @track_info %Radio.Spotify.TrackInfo{
    artist_names: ["Rick Astley"],
    duration_ms: 213_573,
    name: "Never Gonna Give You Up",
    uri: "spotify:track:4cOdK2wGLETKBW3PvgPWqT"
  }

  @device_id "abcdefghijklmnopqrstuvwxyz01234567890000"

  @token_info %Radio.Spotify.TokenInfo{
    access_token: "abc123",
    refresh_token: "xyz987",
    expires_in: "3600",
    token_type: "Bearer"
  }

  setup :verify_on_exit!

  setup do
    child_spec = %{
      id: TrackQueueTest,
      start: {Radio.TrackQueue, :start_link, [@station_name, [name: TrackQueueTest]]}
    }

    server_pid = start_supervised!(child_spec)

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
    assert_receive {^ref, :get_track}

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

  test "starts playback of the current queue on a specific device", %{server: pid} do
    parent = self()
    ref = make_ref()

    expect(Radio.Spotify.MockApiClient, :start_playback, fn _access_token, _device_id, _uris ->
      send(parent, {ref, :start_playback})
      :ok
    end)

    Radio.TrackQueue.play_on(pid, @device_id, @token_info)

    assert_receive {^ref, :start_playback}
  end
end
