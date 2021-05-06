defmodule Radio.Context do
  defstruct [:user, :access_token, :selected_device]

  @type t :: %__MODULE__{
          user: Radio.Spotify.User.t(),
          access_token: String.t(),
          selected_device: Radio.Spotify.Device.t() | nil
        }

  @spec select_device(context :: t(), device :: Radio.Spotify.Device.t()) :: t()
  def select_device(context, device), do: Map.put(context, :selected_device, device)

  @spec deselect_device(context :: t()) :: t()
  def deselect_device(context), do: Map.put(context, :selected_device, nil)
end
