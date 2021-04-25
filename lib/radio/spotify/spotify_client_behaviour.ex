defmodule Radio.Spotify.ApiClientBehaviour do
  @callback get_track(String.t()) :: tuple()
end
