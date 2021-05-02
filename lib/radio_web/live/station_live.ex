defmodule RadioWeb.StationLive do
  use RadioWeb, :live_view

  alias Phoenix.PubSub
  alias Radio.Spotify
  alias Radio.Context
  alias Radio.UserContext

  @spec api_client() :: module()
  def api_client, do: Application.get_env(:radio, :spotify_api)

  @impl true
  def mount(%{"station" => name} = _params, session, socket) do
    # ensure the radio station exists when someone visits the URL
    station_name = String.trim(name)
    {:ok, _station} = Radio.StationRegistry.lookup(station_name)

    case session do
      %{"current_user_id" => user_id} ->
        if connected?(socket) do
          PubSub.subscribe(Radio.PubSub, "station:#{station_name}")
          PubSub.subscribe(Radio.PubSub, "user:#{user_id}")

          Process.send(self(), :fetch_devices, [])
        end

        context = UserContext.get(Radio.UserContext, user_id)
        track_list = Radio.StationRegistry.upcoming(station_name)

        if is_nil(context) do
          {:ok, socket |> redirect(to: "/login?back=#{station_name}")}
        else
          {:ok,
           socket
           |> assign(
             station_name: station_name,
             devices: [],
             current_user_id: user_id,
             context: context,
             current_queue: track_list,
             upcoming_tracks: Enum.drop(track_list, 1)
           )}
        end

      _ ->
        {:ok, socket |> redirect(to: "/login?back=#{station_name}")}
    end
  end

  @impl true
  def handle_event("refresh", _params, socket) do
    %{current_user_id: user_id} = socket.assigns

    Phoenix.PubSub.broadcast(Radio.PubSub, "user:#{user_id}", :refresh_page)

    {:noreply, socket}
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
        if Spotify.valid_song_link?(song_link) do
          track_id = Spotify.track_id_from_song_link(song_link)

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
  def handle_event("play-on", %{"device-id" => id, "device-name" => name}, socket) do
    %{station_name: station_name, current_user_id: user_id} = socket.assigns

    {:ok, station} = Radio.StationRegistry.lookup(station_name)

    device = %Spotify.Device{id: id, name: name}

    context = UserContext.get(Radio.UserContext, user_id)
    updated_context = Map.put(context, :selected_device, device)

    with {:ok, _body} <- Radio.TrackQueue.play_on(station, id, context.access_token),
         :ok <- UserContext.update(Radio.UserContext, updated_context) do
      {:noreply, socket |> assign(selected_device: device)}
    else
      {:error, %{status: 401}} ->
        {:noreply, socket |> redirect(to: "/login?back=#{station_name}")}

      _ ->
        {:noreply, socket}
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
  def handle_info({:new_track, track_info}, socket) do
    %{station_name: station_name, current_user_id: user_id} = socket.assigns

    socket =
      case UserContext.get(Radio.UserContext, user_id) do
        %Context{selected_device: %Spotify.Device{} = device} = context ->
          case api_client().queue_track(context.access_token, track_info.uri) do
            {:ok, _body} ->
              socket |> put_flash(:success, "Queuing #{track_info.name} on #{device.name}")

            {:error, %{status: 401}} ->
              socket |> redirect(to: "/login?back=#{station_name}")

            {:error, _reason} ->
              socket
          end

        _ ->
          socket
      end

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

  @impl true
  def handle_info(:fetch_devices, socket) do
    %{station_name: station_name, current_user_id: user_id} = socket.assigns

    context = UserContext.get(Radio.UserContext, user_id)

    case api_client().get_my_devices(context.access_token) do
      {:ok, devices} ->
        {:noreply, socket |> assign(devices: devices)}

      {:error, %{status: 401}} ->
        {:noreply, socket |> redirect(to: "/login?back=#{station_name}")}

      {:error, _reason} ->
        {:noreply, socket |> assign(devices: [])}
    end
  end

  @impl true
  def handle_info(:refresh_page, socket) do
    %{station_name: station_name} = socket.assigns

    {:noreply, redirect(socket, to: "/login?back=#{station_name}")}
  end
end
