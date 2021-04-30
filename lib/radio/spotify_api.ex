defmodule Radio.SpotifyApi do
  @api_url "https://api.spotify.com"
  @token_url "https://accounts.spotify.com/api/token"

  def track_id_from_song_link(song_link) do
    %URI{path: path} = URI.parse(song_link)
    String.replace_prefix(path, "/track/", "")
  end

  def valid_song_link?(song_link) do
    case URI.parse(song_link) do
      %URI{host: "open.spotify.com"} ->
        true

      _ ->
        false
    end
  end

  def refresh_token(refresh_token) do
    encoded_body =
      %{grant_type: "refresh_token", refresh_token: refresh_token} |> URI.encode_query()

    headers = [
      Authorization: "Basic #{basic_auth_credentials()}",
      "Content-Type": "application/x-www-form-urlencoded",
      Accept: "application/json"
    ]

    handle_response(
      HTTPoison.post(@token_url, encoded_body, headers),
      fn %{
           "access_token" => access_token,
           "refresh_token" => refresh_token,
           "token_type" => token_type,
           "expires_in" => expires_in
         } ->
        %Radio.Spotify.TokenInfo{
          access_token: access_token,
          refresh_token: refresh_token,
          token_type: token_type,
          expires_in: expires_in
        }
      end
    )
  end

  def get_devices(access_token) do
    headers = [
      Accept: "application/json",
      Authorization: "Bearer #{access_token}"
    ]

    handle_response(
      HTTPoison.get("#{@api_url}/v1/me/player/devices", headers),
      fn %{"devices" => devices} ->
        devices
      end
    )
  end

  defp handle_response(response, success_fn) do
    case response do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, success_fn.(Poison.decode!(body))}

      {:ok, _response} ->
        {:error, :unauthorized}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  defp basic_auth_credentials do
    %{client_id: client_id, client_secret: client_secret} = env_config()

    "#{client_id}:#{client_secret}"
    |> :base64.encode()
    |> String.to_charlist()
    |> Enum.filter(fn c -> c != '\n' end)
    |> to_string
  end

  defp env_config do
    %{
      "SPOTIFY_CLIENT_ID" => client_id,
      "SPOTIFY_CLIENT_SECRET" => client_secret,
      "SPOTIFY_REDIRECT_URI" => redirect_uri
    } = System.get_env()

    %{client_id: client_id, client_secret: client_secret, redirect_uri: redirect_uri}
  end
end
