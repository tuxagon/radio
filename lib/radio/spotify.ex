defmodule Radio.Spotify do
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

  def play_on_device(access_token, device_id, uri) do
    {:error, :not_implemented}
  end

  def user_profile(%Radio.TokenInfo{} = token_info) do
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
           "token_type" => token_type
         } ->
        %Radio.TokenInfo{
          access_token: access_token,
          refresh_token: refresh_token,
          token_type: token_type
        }
      end
    )
  end

  def track_info(track_id) do
    # {:ok, %{duration_ms: 346_013, url: "spotify:track:4nhVsU2AMH8nXG1NXIkzO2"}}
    case get_token_from_client_credentials() do
      {:ok, %{access_token: access_token, token_type: token_type}} ->
        headers = [
          Authorization: "#{token_type} #{access_token}",
          "Content-Type": "application/json",
          Accept: "application/json"
        ]

        case HTTPoison.get("#{@api_url}/v1/audio-features/#{track_id}", headers) do
          {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
            %{"duration_ms" => duration_ms, "uri" => uri} = Poison.decode!(body)

            {:ok, %{duration_ms: duration_ms, uri: uri}}

          {:ok, %HTTPoison.Response{body: body}} ->
            %{"error" => %{"message" => message}} = Poison.decode!(body)

            {:error, message}

          {:error, %HTTPoison.Error{reason: reason}} ->
            {:error, reason}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp get_token_from_client_credentials do
    encoded_body = %{grant_type: "client_credentials"} |> URI.encode_query()

    headers = [
      Authorization: "Basic #{basic_auth_credentials()}",
      "Content-Type": "application/x-www-form-urlencoded",
      Accept: "application/json"
    ]

    case HTTPoison.post(@token_url, encoded_body, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        %{"access_token" => access_token, "token_type" => token_type} = Poison.decode!(body)

        {:ok, %{access_token: access_token, token_type: token_type}}

      {:ok, _response} ->
        {:error, :unauthorized}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
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

  defp build_user_api_headers(%Radio.TokenInfo{access_token: access_token, token_type: token_type}) do
    [{:Authorization, "#{token_type} #{access_token}"} | @json_headers]
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
