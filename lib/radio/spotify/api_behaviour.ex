defmodule Radio.Spotify.ApiBehaviour do
  @callback exchange_auth_code_for_token(code :: String.t()) :: tuple()
  @callback get_my_user(access_token :: String.t()) :: tuple()
  @callback get_track(track_id :: String.t()) :: tuple()
  @callback start_playback(
              access_token :: String.t(),
              device_id :: String.t(),
              uris :: [String.t()]
            ) :: tuple()
end
