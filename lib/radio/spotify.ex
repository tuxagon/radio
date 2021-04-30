defmodule Radio.Spotify do
  defp client_id, do: Application.get_env(:radio, :spotify)[:client_id]
  defp redirect_uri, do: Application.get_env(:radio, :spotify)[:redirect_uri]

  def authorize_url do
    auth_state = gen_auth_state_token()

    scope =
      [
        "streaming",
        "user-read-email",
        "user-read-private",
        "user-read-playback-state",
        "user-modify-playback-state",
        "user-read-currently-playing"
      ]
      |> Enum.join(" ")

    params =
      %{
        response_type: "code",
        client_id: client_id(),
        scope: scope,
        redirect_uri: redirect_uri(),
        state: auth_state
      }
      |> URI.encode_query()

    %{url: "https://accounts.spotify.com/authorize?#{params}", state: auth_state}
  end

  defp gen_auth_state_token do
    :crypto.strong_rand_bytes(24) |> :base64.encode()
  end
end
