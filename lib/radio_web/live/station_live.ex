defmodule RadioWeb.StationLive do
  use RadioWeb, :live_view

  alias Phoenix.PubSub

  @impl true
  def mount(
        %{"station" => name} = _params,
        %{"token_info" => token_info, "spotify_user" => spotify_user} = _session,
        socket
      ) do
    # ensure the radio station exists when someone visits the URL
    station_name = String.trim(name)
    {:ok, station} = Radio.StationRegistry.lookup(station_name)

    if connected?(socket) do
      PubSub.subscribe(Radio.PubSub, "station:#{station_name}")
    end

    track_list = Radio.TrackQueue.current_queue(station)

    devices =
      case Radio.SpotifyApi.get_devices(token_info.access_token) do
        {:ok, devices} ->
          devices

        {:error, _reason} ->
          []
      end

    {:ok,
     assign(socket,
       station: name,
       spotify_user: spotify_user,
       devices: devices,
       current_track: List.first(track_list),
       upcoming_tracks: Enum.drop(track_list, 1)
     )}
  end

  @impl true
  def handle_event("queue", %{"song_link" => song_link}, socket) do
    %{station: name} = socket.assigns

    case String.trim(song_link) do
      "" ->
        {:noreply,
         socket
         |> put_flash(:error, "Missing Song Link")}

      song_link ->
        if Radio.SpotifyApi.valid_song_link?(song_link) do
          track_id = Radio.SpotifyApi.track_id_from_song_link(song_link)

          Radio.StationRegistry.queue_track(name, track_id)

          {:noreply,
           socket
           |> put_flash(:success, "All queued up!")}
        else
          {:noreply,
           socket
           |> put_flash(:error, "Invalid Song Link")
           |> assign(song_link: song_link)}
        end
    end
  end

  @impl true
  def handle_event(
        "play-on",
        %{"token" => access_token, "id" => device_id, "name" => device_name} = _params,
        socket
      ) do
    %{station: name} = socket.assigns

    {:ok, station} = Radio.StationRegistry.lookup(name)

    Radio.TrackQueue.play_on(station, device_id, %Radio.TokenInfo{access_token: access_token})

    {:noreply, socket |> put_flash(:success, "Sending to #{device_name}")}
  end
end
