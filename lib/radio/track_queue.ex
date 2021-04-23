defmodule Radio.TrackQueue do
  use GenServer

  alias Radio.Spotify

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def add_track(server, track_id) do
    GenServer.cast(server, {:add_track, track_id})
  end

  def current_queue(server) do
    GenServer.call(server, :current_queue)
  end

  def play_on(server, device_id, token_info) do
    GenServer.cast(server, {:play_on, device_id, token_info})
  end

  @impl true
  def init(:ok) do
    {:ok, :queue.new()}
  end

  @impl true
  def handle_call(:current_queue, _from, track_queue) do
    {:reply, :queue.to_list(track_queue), track_queue}
  end

  @impl true
  def handle_cast({:add_track, track_id}, track_queue) do
    case Spotify.track_info(track_id) do
      {:ok, %{duration_ms: duration_ms} = track_info} ->
        if :queue.is_empty(track_queue) do
          Process.send_after(self(), :next_track, duration_ms)
        end

        {:noreply, :queue.in(track_info, track_queue)}

      {:error, _reason} ->
        {:noreply, track_queue}
    end
  end

  @impl true
  def handle_info(:next_track, track_queue) do
    {_, q} = :queue.out(track_queue)

    case :queue.peek(q) do
      {:value, %{duration_ms: duration_ms}} ->
        Process.send_after(self(), :next_track, duration_ms)

        {:noreply, q}

      :empty ->
        {:noreply, q}
    end
  end
end
