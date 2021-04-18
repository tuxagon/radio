defmodule AgentRadio.Spotify do
  @api_url "https://api.spotify.com"
  @token_url "https://accounts.spotify.com/api/token"

  def authorize_url do
    %{client_id: client_id, redirect_uri: redirect_uri} = env_config()

    auth_state = auth_state_token()

    scope = ["streaming", "user-read-email", "user-read-private"] |> Enum.join(" ")

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

    case HTTPoison.post(@token_url, encoded_body, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        %{"access_token" => access_token, "refresh_token" => refresh_token} = Poison.decode!(body)

        {:ok, %{access_token: access_token, refresh_token: refresh_token}}

      {:ok, _response} ->
        {:error, :unauthorized}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
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
