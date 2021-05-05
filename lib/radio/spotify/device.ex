defmodule Radio.Spotify.Device do
  @moduledoc """
  Information related to a specific Spotify user's device
  """

  defstruct [:id, :name, :type]

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          type: String.t()
        }
end
