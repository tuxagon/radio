defmodule RadioWeb.TokenChannel do
  use Phoenix.Channel

  def join("token:all", _message, socket) do
    {:ok, socket.assigns[:user_id], socket}
  end

  def join("token:" <> user_id, _message, socket) do
    {:ok, socket}
  end
end
