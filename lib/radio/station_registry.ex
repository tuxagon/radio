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
    {:ok, {%{}, %{}}}
  end

  @impl true
  def handle_call({:lookup, name}, _from, {stations, refs}) do
    if Map.has_key?(stations, name) do
      {:reply, Map.fetch(stations, name), {stations, refs}}
    else
      {pid, {stations, refs}} = register_station(name, {stations, refs})

      {:reply, {:ok, pid}, {stations, refs}}
    end
  end

  @impl true
  def handle_call({:upcoming, name}, _from, {stations, refs}) do
    {:ok, station} = Map.fetch(stations, name)

    track_list = Radio.TrackQueue.current_queue(station)

    {:reply, track_list, {stations, refs}}
  end

  @impl true
  def handle_cast({:queue_track, name, track_id}, {stations, refs}) do
    {:ok, station} = Map.fetch(stations, name)

    Radio.TrackQueue.add_track(station, track_id)

    {:noreply, {stations, refs}}
  end

  defp register_station(name, {stations, refs}) do
    child_spec = %{id: Radio.TrackQueue, start: {Radio.TrackQueue, :start_link, [name, []]}}
    {:ok, pid} = DynamicSupervisor.start_child(Radio.StationSupervisor, child_spec)

    ref = Process.monitor(pid)
    refs = Map.put(refs, ref, name)
    stations = Map.put(stations, name, pid)
    {pid, {stations, refs}}
  end
end
