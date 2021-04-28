defmodule Radio.Spotify.TokenInfo do
  @moduledoc """
  Holds relevant information about a token for the Spotify API on the behalf of a user.

  * `:access_token`: Short-lived access token.
  * `:refresh_token`: Long-lived token used to obtain a new access token.
  * `:expires_in`: Holds how many seconds the access token will be considered authorized.
  * `:token_type`: Holds what kind of token the access token is, such as `Bearer`

  """
  defstruct [:access_token, :refresh_token, :expires_in, :token_type]

  @type t :: %__MODULE__{
          access_token: String.t(),
          refresh_token: String.t(),
          expires_in: String.t(),
          token_type: String.t()
        }

  @doc """
  Returns a tuple representing an Authorization header from the token information
  """
  @spec authorization_header(t()) :: tuple()
  def authorization_header(%__MODULE__{
        token_type: token_type,
        access_token: access_token
      }) do
    {:Authorization, "#{token_type} #{access_token}"}
  end
end
