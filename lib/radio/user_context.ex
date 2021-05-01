defmodule Radio.UserContext do
  use GenServer

  alias Radio.Context

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def insert(server, %Context{} = context) do
    GenServer.cast(server, {:insert, context})
  end

  def get(server, user_id) do
    GenServer.call(server, {:get, user_id})
  end

  @impl true
  def init(:ok) do
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:insert, context}, user_contexts) do
    {:noreply, Map.put(user_contexts, context.user.id, context)}
  end

  @impl true
  def handle_call({:get, user_id}, _from, user_contexts) do
    {:reply, Map.get(user_contexts, user_id), user_contexts}
  end
end
