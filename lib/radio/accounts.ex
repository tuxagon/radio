defmodule Radio.Accounts do
  @topic inspect(__MODULE__)

  def subscribe do
    Phoenix.PubSub.subscribe(Radio.PubSub, @topic)
  end

  def subscribe(spotify_user_id) do
    Phoenix.PubSub.subscribe(Radio.PubSub, @topic <> "#{spotify_user_id}")
  end

  defp notify_subscribers({:ok, result}, event) do
    Phoenix.PubSub.broadcast(Radio.PubSub, @topic, {__MODULE__, event, result})

    Phoenix.PubSub.broadcast(
      Radio.PubSub,
      @topic <> "#{result.id}",
      {__MODULE__, event, result}
    )

    {:ok, result}
  end

  defp notify_subscribers({:error, reason}, _), do: {:error, reason}
end
