defmodule Radio.TokenStore do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def add(server, user_id, %Radio.TokenInfo{} = token_info) do
    GenServer.cast(server, {:add, user_id, token_info})
  end

  def get_access_token(server, user_id) do
    GenServer.call(server, {:get_access_token, user_id})
  end

  def refresh(server, user_id) do
    GenServer.call(server, {:refresh, user_id})
  end

  @impl true
  def init(:ok) do
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:add, user_id, token_info}, token_store) do
    {:noreply, Map.put(token_store, user_id, token_info)}
  end

  @impl true
  def handle_call({:get_access_token, user_id}, _from, token_store) do
    case Map.get(token_store, user_id) do
      %{access_token: access_token} ->
        {:reply, {:ok, access_token}, token_store}

      _ ->
        {:reply, {:error, :no_token}, token_store}
    end
  end

  @impl true
  def handle_call({:refresh, user_id}, _from, token_store) do
    case Map.get(token_store, user_id) do
      %{refresh_token: refresh_token} ->
        case Radio.Spotify.refresh_token(refresh_token) do
          {:ok, %Radio.TokenInfo{access_token: access_token} = token_info} ->
            {:reply, {:ok, access_token}, Map.put(token_store, user_id, token_info)}

          _ ->
            {:reply, {:error, :unable_to_refresh}, token_store}
        end

      _ ->
        {:reply, {:error, :no_token}, token_store}
    end
  end
end
