defmodule Radio.TokenRefreshRegistry do
  use GenServer

  alias Radio.Spotify.TokenInfo

  @me __MODULE__

  @spec api_client() :: module()
  def api_client, do: Application.get_env(:radio, :spotify_api)

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, Keyword.put_new(opts, :name, @me))
  end

  def lookup(server \\ @me, user_id) do
    GenServer.call(server, {:lookup, user_id})
  end

  def put(server \\ @me, user_id, refresh_token, expires_in) do
    GenServer.cast(server, {:put, user_id, refresh_token, expires_in})
  end

  def remove(server \\ @me, user_id) do
    GenServer.cast(server, {:remove, user_id})
  end

  @impl true
  def init(:ok) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:lookup, user_id}, _from, registry) do
    {:reply, {:ok, Map.fetch(registry, user_id)}, registry}
  end

  @impl true
  def handle_cast({:put, user_id, refresh_token, expires_in}, registry) do
    IO.puts("PUT TOKEN")
    Process.send_after(self(), {:refresh, user_id, refresh_token}, refresh_delay(expires_in))

    {:noreply, Map.put(registry, user_id, refresh_token)}
  end

  @impl true
  def handle_cast({:remove, user_id}, registry) do
    {:noreply, Map.delete(registry, user_id)}
  end

  @impl true
  def handle_info({:refresh, user_id, refresh_token}, registry) do
    IO.puts("TRY REFRESH")

    case api_client().refresh_token(%TokenInfo{refresh_token: refresh_token}) do
      {:ok, %TokenInfo{} = token_info} ->
        RadioWeb.Endpoint.broadcast("token:#{user_id}", "refreshed", %{
          token: token_info.access_token,
          type: token_info.token_type
        })

        GenServer.cast(self(), {:put, user_id, refresh_token, token_info.expires_in})

      _error ->
        GenServer.cast(self(), {:remove, user_id})
    end

    {:noreply, registry}
  end

  defp refresh_delay(expires_in) do
    5
    # (expires_in * 0.8) |> floor
  end
end
