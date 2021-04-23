defmodule Radio.DeviceRegistry do
  use GenServer

  alias Radio.Spotify

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def get_devices(server, token_info) do
    GenServer.call(server, {:get_devices, token_info})
  end

  @impl true
  def init(:ok) do
    {:ok, []}
  end

  @impl true
  def handle_call({:get_devices, token_info}, _from, known_devices) do
    case Spotify.get_devices(token_info.access_token) do
      {:ok, devices} ->
        {:reply, devices, known_devices}

      {:error, _reason} ->
        {:reply, [], known_devices}
    end
  end
end
