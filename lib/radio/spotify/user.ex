defmodule Radio.Spotify.User do
  @moduledoc """
  Information related to a specific Spotify user
  """

  defstruct [:id, :display_name]

  @type t :: %__MODULE__{
          id: String.t(),
          display_name: String.t()
        }
end
