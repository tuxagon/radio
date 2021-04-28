defmodule RadioWeb.StationLive do
  use RadioWeb, :live_view

  alias Phoenix.PubSub

  @impl true
  def mount(
        %{"station" => name} = _params,
        %{"token_info" => token_info} = _session,
        socket
      ) do
    # ensure the radio station exists when someone visits the URL
    station_name = String.trim(name)
    {:ok, _station} = Radio.StationRegistry.lookup(station_name)

    if connected?(socket) do
      PubSub.subscribe(Radio.PubSub, "station:#{station_name}")
    end

    track_list = Radio.StationRegistry.upcoming(station_name)

    devices =
      case Radio.SpotifyApi.get_devices(token_info.access_token) do
        {:ok, devices} ->
          devices

        {:error, _reason} ->
          []
      end

    IO.inspect(socket.assigns)

    {:ok,
     socket
     |> assign(
       station_name: name,
       devices: devices,
       current_queue: track_list,
       current_track: List.first(track_list),
       upcoming_tracks: Enum.drop(track_list, 1),
       selected_device: socket.assigns[:device_id]
     )}
  end

  @impl true
  def handle_event("queue", %{"song_link" => song_link}, socket) do
    %{station_name: name} = socket.assigns

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
  def handle_event("set-device", params, socket) do
    case params do
      %{"device_id" => device_id, "device_name" => device_name} ->
        {:noreply,
         socket
         |> put_flash(:success, "Playing queue on #{device_name}")
         |> assign(:device_id, device_id)}

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:new_track, _track_info}, socket) do
    %{station_name: station_name} = socket.assigns

    current_queue = Radio.StationRegistry.upcoming(station_name)

    {:noreply,
     socket
     |> assign(
       current_queue: current_queue,
       current_track: List.first(current_queue),
       upcoming_tracks: Enum.drop(current_queue, 1)
     )}
  end

  @impl true
  def handle_info({:next_track, _track_info}, socket) do
    %{station_name: station_name} = socket.assigns

    current_queue = Radio.StationRegistry.upcoming(station_name)

    {:noreply,
     socket
     |> assign(
       current_queue: current_queue,
       current_track: List.first(current_queue),
       upcoming_tracks: Enum.drop(current_queue, 1)
     )}
  end

  @impl true
  def handle_info(:empty_queue, socket) do
    {:noreply,
     socket
     |> assign(
       current_queue: [],
       current_track: nil,
       upcoming_tracks: []
     )}
  end
end
