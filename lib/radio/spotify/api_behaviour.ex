defmodule Radio.Spotify.ApiBehaviour do
  @callback get_track(track_id :: String.t()) :: tuple()
  @callback start_playback(
              access_token :: String.t(),
              device_id :: String.t(),
              uris :: [String.t()]
            ) :: tuple()
end
