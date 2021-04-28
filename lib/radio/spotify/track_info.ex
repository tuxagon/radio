defmodule Radio.Spotify.TrackInfo do
  @moduledoc """
  Information related to a specific Spotify track
  """

  defstruct [:duration_ms, :name, :uri, :artist_names]
end
