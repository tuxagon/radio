defmodule Radio.Spotify.ApiClient do
  @behaviour Radio.Spotify.ApiBehaviour

  @type error :: {:error, %{message: any, status: nil | integer}}

  alias Radio.Spotify.Device
  alias Radio.Spotify.TrackInfo
  alias Radio.Spotify.User

  defp client_id, do: Application.get_env(:radio, :spotify)[:client_id]
  defp client_secret, do: Application.get_env(:radio, :spotify)[:client_secret]
  defp redirect_uri, do: Application.get_env(:radio, :spotify)[:redirect_uri]
  defp http_client, do: Application.get_env(:radio, :http_client)

  def default_opts(), do: Application.get_env(:radio, :spotify)

  @doc """
  Gets track information from Spotify for a provided `track_id`.

  ## Examples

      iex> Radio.Spotify.ApiClient.get_track("4cOdK2wGLETKBW3PvgPWqT")
      {:ok,
      %Radio.Spotify.TrackInfo{
        artist_names: ["Rick Astley"],
        duration_ms: 213573,
        name: "Never Gonna Give You Up",
        uri: "spotify:track:4cOdK2wGLETKBW3PvgPWqT"
      }}

  """
  @impl true
  @spec get_track(String.t(), Keyword.t()) :: {:ok, Radio.Spotify.TrackInfo.t()} | error()
  def get_track(track_id, opts \\ default_opts()) do
    case exchange_client_credentials_for_token(opts) do
      {:ok, %{"access_token" => access_token}} ->
        headers = [token_auth(access_token) | [json_content(), accept_json()]]

        case "/v1/tracks/#{track_id}" |> do_api_get(headers, opts) do
          {:ok, body} ->
            track_info = %TrackInfo{
              duration_ms: body["duration_ms"],
              name: body["name"],
              uri: body["uri"],
              artist_names: Enum.map(body["artists"], fn %{"name" => name} -> name end)
            }

            {:ok, track_info}

          {:error, reason} ->
            {:error, reason}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @impl true
  @spec search_tracks(
          search_term :: String.t(),
          limit :: integer(),
          offset :: integer,
          Keyword.t()
        ) :: {:ok, [Radio.Spotify.Device.t()]} | error()
  def search_tracks(search_term, limit, offset, opts \\ default_opts()) do
    params =
      %{q: search_term, type: "track", limit: limit, offset: offset}
      |> URI.encode_query()

    with {:ok, %{"access_token" => access_token}} <- exchange_client_credentials_for_token(opts),
         headers <- [token_auth(access_token) | [json_content(), accept_json()]],
         {:ok, %{"tracks" => %{"items" => results}}} <-
           "/v1/search?#{params}" |> do_api_get(headers, opts) do
      found_tracks =
        results
        |> Enum.map(fn result ->
          %TrackInfo{
            duration_ms: result["duration_ms"],
            name: result["name"],
            uri: result["uri"],
            artist_names: Enum.map(result["artists"], fn %{"name" => name} -> name end)
          }
        end)

      {:ok, found_tracks}
    else
      {:ok, _body} ->
        {:ok, []}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Get current user's devices.
  """
  @impl true
  @spec get_my_devices(String.t(), Keyword.t()) :: {:ok, [Radio.Spotify.Device.t()]} | error()
  def get_my_devices(access_token, opts \\ default_opts()) do
    headers = [token_auth(access_token) | [json_content(), accept_json()]]

    case "/v1/me/player/devices" |> do_api_get(headers, opts) do
      {:ok, %{"devices" => devices}} ->
        {:ok,
         devices
         |> Enum.map(fn %{"id" => id, "name" => name, "type" => type} ->
           %Device{id: id, name: name, type: type}
         end)}

      {:ok, _body} ->
        spotify_error(nil, "unable to get user devices")

      error ->
        error
    end
  end

  @doc """
  Get current user.
  """
  @impl true
  @spec get_my_user(String.t(), Keyword.t()) :: {:ok, Radio.Spotify.User.t()} | error()
  def get_my_user(access_token, opts \\ default_opts()) do
    headers = [token_auth(access_token) | [json_content(), accept_json()]]

    case "/v1/me" |> do_api_get(headers, opts) do
      {:ok, %{"id" => id, "display_name" => name}} ->
        {:ok, %User{id: id, name: name}}

      {:ok, _body} ->
        spotify_error(nil, "unable to get user profile")

      error ->
        error
    end
  end

  @doc """
  Add track to current queue on a user's active device.
  """
  @spec queue_track(String.t(), String.t(), Keyword.t()) :: {:ok, any} | error()
  def queue_track(access_token, uri, opts \\ default_opts()) do
    headers = [token_auth(access_token) | [json_content(), accept_json()]]

    "/v1/me/player/queue?uri=#{uri}" |> do_api_post(nil, headers, opts)
  end

  @doc """
  Starts playback for the list of `uris` on the device specified with `device_id`.
  """
  @impl true
  @spec start_playback(String.t(), String.t(), [String.t()], Keyword.t()) :: {:ok, any} | error()
  def start_playback(access_token, device_id, uris, opts \\ default_opts()) do
    headers = [token_auth(access_token) | [json_content(), accept_json()]]

    encoded_body = %{uris: uris} |> Poison.encode!()

    "/v1/me/player/play?device_id=#{device_id}" |> do_api_put(encoded_body, headers, opts)
  end

  @doc """
  Refreshes a user's access token.
  """
  @spec refresh_token(String.t(), Keyword.t()) :: {:ok, any} | error()
  def refresh_token(refresh_token, opts \\ default_opts()) do
    headers = [basic_auth() | [accept_json(), form_content()]]

    encoded_body =
      %{
        grant_type: "refresh_token",
        refresh_token: refresh_token
      }
      |> URI.encode_query()

    opts[:token_url]
    |> do_post(encoded_body, headers)
  end

  @doc """
  Gets an access token for an auth code.
  """
  @impl true
  @spec exchange_auth_code_for_token(String.t(), Keyword.t()) :: {:ok, any} | error()
  def exchange_auth_code_for_token(code, opts \\ default_opts()) do
    encoded_body =
      %{
        code: code,
        grant_type: "authorization_code",
        redirect_uri: redirect_uri()
      }
      |> URI.encode_query()

    headers = [basic_auth() | [accept_json(), form_content()]]

    opts[:token_url]
    |> do_post(encoded_body, headers)
  end

  defp exchange_client_credentials_for_token(opts) do
    encoded_body = %{grant_type: "client_credentials"} |> URI.encode_query()

    headers = [basic_auth() | [accept_json(), form_content()]]

    opts[:token_url]
    |> do_post(encoded_body, headers)
  end

  defp handle_response(resp) do
    case resp do
      {:ok, %{body: body, status_code: 200}} ->
        {:ok, Poison.decode!(body)}

      {:ok, %{body: body, status_code: 204}} ->
        {:ok, body}

      {:ok, %{body: body, status_code: status}} ->
        case Poison.decode!(body) do
          %{"error" => %{"message" => message}} ->
            spotify_error(status, message)

          %{"error_description" => message} ->
            spotify_error(status, message)

          error ->
            spotify_error(status, error)
        end

      {:error, %HTTPoison.Error{} = error} ->
        spotify_error(error.id, error.reason)
    end
  end

  defp do_api_get(url, headers, opts) do
    (opts[:api_url] <> url)
    |> http_client().get(headers)
    |> handle_response()
  end

  defp do_api_post(url, body, headers, opts) do
    (opts[:api_url] <> url)
    |> http_client().post(body, headers)
    |> handle_response()
  end

  defp do_api_put(url, body, headers, opts) do
    (opts[:api_url] <> url)
    |> http_client().put(body, headers)
    |> handle_response()
  end

  defp do_post(url, body, headers) do
    url
    |> http_client().post(body, headers)
    |> handle_response()
  end

  defp spotify_error(status, message) do
    {:error, %{status: status, message: message}}
  end

  defp accept_json do
    {:Accept, "application/json"}
  end

  defp json_content do
    {:"Content-Type", "application/json"}
  end

  defp form_content do
    {:"Content-Type", "application/x-www-form-urlencoded"}
  end

  defp token_auth(token) do
    {:Authorization, "Bearer #{token}"}
  end

  defp basic_auth do
    token =
      [client_id(), client_secret()]
      |> Enum.join(":")
      |> :base64.encode()
      |> String.to_charlist()
      |> Enum.filter(fn c -> c != '\n' end)
      |> to_string

    {:Authorization, "Basic #{token}"}
  end
end
