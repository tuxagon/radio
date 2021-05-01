defmodule Radio.Spotify.ApiClientBehaviour do
  @type spotify_success :: {:ok, any}
  @type spotify_error :: {:error, %{message: any, status: nil | integer}}

  @type spotify_response :: spotify_success() | spotify_error()

  @callback get_track(String.t()) :: spotify_response()

  @callback exchange_auth_code_for_token(String.t()) :: spotify_response()
  @callback get_my_devices(String.t()) :: spotify_response()
  @callback get_my_user(String.t()) :: spotify_response()
  @callback refresh_token(String.t()) :: spotify_response()
  @callback start_playback(String.t(), String.t(), [String.t()]) ::
              spotify_response()
end
