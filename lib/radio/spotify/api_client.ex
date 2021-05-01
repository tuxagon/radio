defmodule Radio.Spotify.ApiClient do
  use HTTPoison.Base

  @behaviour Radio.Spotify.ApiClientBehaviour

  @api_url "https://api.spotify.com"
  @token_url "https://accounts.spotify.com/api/token"

  alias Radio.Spotify.Device
  alias Radio.Spotify.TrackInfo
  alias Radio.Spotify.User

  defp client_id, do: Application.get_env(:radio, :spotify)[:client_id]
  defp client_secret, do: Application.get_env(:radio, :spotify)[:client_secret]
  defp redirect_uri, do: Application.get_env(:radio, :spotify)[:redirect_uri]

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
  @spec get_track(String.t()) ::
          {:ok, Radio.Spotify.TrackInfo.t()} | Radio.Spotify.ApiClientBehaviour.spotify_error()
  @impl true
  def get_track(track_id) do
    case exchange_client_credentials_for_token() do
      {:ok, %{"access_token" => access_token}} ->
        headers = [token_auth(access_token) | [json_content(), accept_json()]]

        case "/v1/tracks/#{track_id}" |> do_api_get(headers) do
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

  @doc """
  Get current user's devices.
  """
  @spec get_my_devices(String.t()) ::
          {:ok, Radio.Spotify.Device.t()} | Radio.Spotify.ApiClientBehaviour.spotify_error()
  @impl true
  def get_my_devices(access_token) do
    headers = [token_auth(access_token) | [json_content(), accept_json()]]

    case "/v1/me/player/devices" |> do_api_get(headers) do
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
  @spec get_my_user(String.t()) ::
          {:ok, Radio.Spotify.User.t()} | Radio.Spotify.ApiClientBehaviour.spotify_error()
  @impl true
  def get_my_user(access_token) do
    headers = [token_auth(access_token) | [json_content(), accept_json()]]

    case "/v1/me" |> do_api_get(headers) do
      {:ok, %{"id" => id, "display_name" => name}} ->
        {:ok, %User{id: id, name: name}}

      {:ok, _body} ->
        spotify_error(nil, "unable to get user profile")

      error ->
        error
    end
  end

  @doc """
  Starts playback for the list of `uris` on the device specified with `device_id`.
  """
  @spec start_playback(String.t(), String.t(), [String.t()]) ::
          Radio.Spotify.ApiClientBehaviour.spotify_response()
  @impl true
  def start_playback(access_token, device_id, uris) do
    headers = [token_auth(access_token) | [json_content(), accept_json()]]

    encoded_body = %{uris: uris} |> Poison.encode!()

    "/v1/me/player/play?device_id=#{device_id}" |> do_api_put(encoded_body, headers)
  end

  @doc """
  Refreshes a user's access token.
  """
  @spec refresh_token(String.t()) :: Radio.Spotify.ApiClientBehaviour.spotify_response()
  @impl true
  def refresh_token(refresh_token) do
    headers = [basic_auth() | [accept_json(), form_content()]]

    encoded_body =
      %{
        grant_type: "refresh_token",
        refresh_token: refresh_token
      }
      |> URI.encode_query()

    @token_url
    |> do_post(encoded_body, headers)
  end

  @doc """
  Gets an access token for an auth code.
  """
  @spec exchange_auth_code_for_token(String.t()) ::
          Radio.Spotify.ApiClientBehaviour.spotify_response()
  @impl true
  def exchange_auth_code_for_token(code) do
    encoded_body =
      %{
        code: code,
        grant_type: "authorization_code",
        redirect_uri: redirect_uri()
      }
      |> URI.encode_query()

    headers = [basic_auth() | [accept_json(), form_content()]]

    @token_url
    |> do_post(encoded_body, headers)
  end

  defp exchange_client_credentials_for_token do
    encoded_body = %{grant_type: "client_credentials"} |> URI.encode_query()

    headers = [basic_auth() | [accept_json(), form_content()]]

    @token_url
    |> do_post(encoded_body, headers)
  end

  defp handle_response(resp) do
    case resp do
      {:ok, %{body: body, status_code: 200}} ->
        {:ok, Poison.decode!(body)}

      {:ok, %{body: body, status_code: 204}} ->
        {:ok, body}

      {:ok, %{body: body, status_code: status}} ->
        spotify_error(status, Poison.decode!(body)["message"])

      {:error, error} ->
        spotify_error(error.id, error.reason)
    end
  end

  defp do_api_get(url, headers) do
    (@api_url <> url)
    |> get(headers)
    |> handle_response()
  end

  defp do_api_put(url, body, headers) do
    (@api_url <> url)
    |> put(body, headers)
    |> handle_response()
  end

  defp do_post(url, body, headers) do
    url
    |> post(body, headers)
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
