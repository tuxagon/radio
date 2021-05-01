defmodule Radio.Context do
  defstruct [:user, :access_token, :selected_device]

  @type t :: %__MODULE__{
          user: Radio.Spotify.User.t(),
          access_token: String.t(),
          selected_device: String.t()
        }
end
