defmodule Radio.Spotify.ApiClient do
  use HTTPoison.Base

  @behaviour Radio.Spotify.ApiClientBehaviour

  @api_url "https://api.spotify.com"
  @token_url "https://accounts.spotify.com/api/token"

  alias Radio.Spotify.TrackInfo

  defp client_id, do: Application.get_env(:radio, :spotify)[:client_id]
  defp client_secret, do: Application.get_env(:radio, :spotify)[:client_secret]
  defp redirect_uri, do: Application.get_env(:radio, :spotify)[:redirect_uri]

  def get_track(track_id) do
    case exchange_client_credentials_for_token() do
      {:ok, %{"access_token" => access_token, "token_type" => token_type}} ->
        headers = [token_auth(token_type, access_token) | [json_content(), accept_json()]]

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

  defp token_auth(type, token) do
    {:Authorization, "#{type} #{token}"}
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
