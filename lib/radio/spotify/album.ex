defmodule Radio.Spotify.Album do
  @moduledoc """
  Information related to a specific Spotify album
  """

  defstruct [:name, :image_url]

  @type t :: %__MODULE__{
          name: String.t(),
          image_url: String.t()
        }
end
