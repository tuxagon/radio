defmodule Radio.Spotify.User do
  @moduledoc """
  Information related to a specific Spotify user
  """

  defstruct [:id, :name]

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t()
        }
end
