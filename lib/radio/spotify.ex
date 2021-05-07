defmodule Radio.Spotify do
  def default_opts(), do: Application.get_env(:radio, :spotify)

  def scopes,
    do: [
      "user-read-email",
      "user-read-private",
      "user-read-playback-state",
      "user-modify-playback-state",
      "user-read-currently-playing"
    ]

  def authorize_url(opts \\ default_opts()) do
    auth_state = gen_auth_state_token()

    params =
      %{
        response_type: "code",
        client_id: opts[:client_id],
        scope: Enum.join(scopes(), " "),
        redirect_uri: opts[:redirect_uri],
        state: auth_state
      }
      |> URI.encode_query()

    {[opts[:authorize_url], params] |> Enum.join("?"), auth_state}
  end

  def track_id_from_song_link(song_link) do
    %URI{path: path} = URI.parse(song_link)

    if path == song_link, do: nil, else: String.replace_prefix(path, "/track/", "")
  end

  def valid_song_link?(song_link) do
    case URI.parse(song_link) do
      %URI{host: "open.spotify.com"} ->
        true

      _ ->
        false
    end
  end

  defp gen_auth_state_token do
    :crypto.strong_rand_bytes(24) |> :base64.encode()
  end
end
