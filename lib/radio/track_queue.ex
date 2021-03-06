defmodule Radio.TrackQueue do
  use GenServer, restart: :temporary

  alias Radio.Spotify.TrackInfo

  defp spotify_api_client, do: Application.get_env(:radio, :spotify_api_client)

  @spec start_link(String.t(), GenServer.options()) :: GenServer.on_start()
  def start_link(name, opts) do
    GenServer.start_link(__MODULE__, {:ok, name}, opts)
  end

  @doc """
  Adds a track into the queue.

  In addition, it sets an expiration on the track for the duration of the track.
  """
  @spec add_track(GenServer.server(), String.t()) :: :ok
  def add_track(server, track_id) do
    GenServer.cast(server, {:add_track, track_id})
  end

  @doc """
  Returns the current queue
  """
  @spec current_queue(GenServer.server()) :: [Radio.Spotify.TrackInfo.t()]
  def current_queue(server) do
    GenServer.call(server, :current_queue)
  end

  @doc """
  Starts playback of the current queue on the device represented by `device_id`.
  """
  def play_on(server, device_id, access_token) do
    GenServer.call(server, {:play_on, device_id, access_token})
  end

  @impl true
  def init({:ok, name}) do
    {:ok, {name, :queue.new()}}
  end

  @impl true
  def handle_call(:current_queue, _from, {_name, track_queue} = state) do
    {:reply, :queue.to_list(track_queue), state}
  end

  @impl true
  def handle_call({:play_on, device_id, access_token}, _from, {_name, track_queue} = state) do
    uris =
      track_queue
      |> :queue.to_list()
      |> Enum.map(fn %{uri: uri} -> uri end)

    {:reply, spotify_api_client().start_playback(access_token, device_id, uris), state}
  end

  @impl true
  def handle_cast({:add_track, track_id}, {name, track_queue}) do
    case spotify_api_client().get_track(track_id) do
      {:ok, %TrackInfo{duration_ms: duration_ms} = track_info} ->
        if :queue.is_empty(track_queue) do
          Process.send_after(self(), :next_track, duration_ms)
        end

        Phoenix.PubSub.broadcast(Radio.PubSub, "station:#{name}", {:new_track, track_info})

        {:noreply, {name, :queue.in(track_info, track_queue)}}

      {:error, _reason} ->
        {:noreply, {name, track_queue}}
    end
  end

  @impl true
  def handle_info(:next_track, {name, track_queue}) do
    {_, q} = :queue.out(track_queue)

    case :queue.peek(q) do
      {:value, %{duration_ms: duration_ms} = track_info} ->
        Phoenix.PubSub.broadcast(Radio.PubSub, "station:#{name}", {:next_track, track_info})

        Process.send_after(self(), :next_track, duration_ms)

        {:noreply, {name, q}}

      :empty ->
        Phoenix.PubSub.broadcast(Radio.PubSub, "station:#{name}", :empty_queue)

        {:noreply, {name, q}}
    end
  end
end
