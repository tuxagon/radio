defmodule Radio.StationRegistry do
  use GenServer

  @me __MODULE__

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, Keyword.put_new(opts, :name, @me))
  end

  def lookup(server \\ @me, station_name) do
    GenServer.call(server, {:lookup, station_name})
  end

  def queue_track(server \\ @me, name, track_id) do
    GenServer.cast(server, {:queue_track, name, track_id})
  end

  def upcoming(server \\ @me, name) do
    GenServer.call(server, {:upcoming, name})
  end

  @impl true
  def init(:ok) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:lookup, name}, _from, stations) do
    if Map.has_key?(stations, name) do
      {:reply, Map.fetch(stations, name), stations}
    else
      {:ok, station} = Radio.TrackQueue.start_link(name, [])

      {:reply, {:ok, station}, Map.put(stations, name, station)}
    end
  end

  @impl true
  def handle_call({:upcoming, name}, _from, stations) do
    {:ok, station} = Map.fetch(stations, name)

    track_list = Radio.TrackQueue.current_queue(station)

    {:reply, track_list, stations}
  end

  @impl true
  def handle_cast({:queue_track, name, track_id}, stations) do
    {:ok, station} = Map.fetch(stations, name)

    Radio.TrackQueue.add_track(station, track_id)

    {:noreply, stations}
  end
end
