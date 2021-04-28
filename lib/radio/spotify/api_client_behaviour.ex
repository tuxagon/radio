defmodule Radio.Spotify.ApiClientBehaviour do
  @callback get_track(String.t()) :: tuple()

  @callback start_playback(Radio.Spotify.TokenInfo.t(), String.t(), [String.t()]) :: tuple() | :ok
end
