defmodule Radio.Spotify.TrackInfo do
  @moduledoc """
  Information related to a specific Spotify track
  """

  defstruct [:duration_ms, :name, :uri, :artist_names, :album]

  @type t :: %__MODULE__{
          duration_ms: integer(),
          name: String.t(),
          uri: String.t(),
          artist_names: [String.t()],
          album: Radio.Spotify.Album.t()
        }
end
