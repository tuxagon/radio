defmodule Radio.SpotifyApi do
  @json_headers [
    Accept: "application/json",
    "Content-Type": "application/json"
  ]

  @api_url "https://api.spotify.com"
  @token_url "https://accounts.spotify.com/api/token"

  def authorize_url do
    %{client_id: client_id, redirect_uri: redirect_uri} = env_config()

    auth_state = auth_state_token()

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
        client_id: client_id,
        scope: scope,
        redirect_uri: redirect_uri,
        state: auth_state
      }
      |> URI.encode_query()

    %{url: "https://accounts.spotify.com/authorize?#{params}", state: auth_state}
  end

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

  def user_profile(%Radio.Spotify.TokenInfo{} = token_info) do
    headers = build_user_api_headers(token_info)

    handle_response(
      HTTPoison.get("#{@api_url}/v1/me", headers),
      fn %{"id" => id, "display_name" => display_name} ->
        %Radio.SpotifyUser{id: id, display_name: display_name}
      end
    )
  end

  def get_token_from_authorization_code(code) do
    %{redirect_uri: redirect_uri} = env_config()

    encoded_body =
      %{
        code: code,
        redirect_uri: redirect_uri,
        grant_type: "authorization_code"
      }
      |> URI.encode_query()

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

  defp build_user_api_headers(%Radio.Spotify.TokenInfo{
         access_token: access_token,
         token_type: token_type
       }) do
    [{:Authorization, "#{token_type} #{String.replace(access_token, "\"", "")}"} | @json_headers]
  end

  defp basic_auth_credentials do
    %{client_id: client_id, client_secret: client_secret} = env_config()

    "#{client_id}:#{client_secret}"
    |> :base64.encode()
    |> String.to_charlist()
    |> Enum.filter(fn c -> c != '\n' end)
    |> to_string
  end

  defp auth_state_token do
    :crypto.strong_rand_bytes(24) |> :base64.encode()
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
