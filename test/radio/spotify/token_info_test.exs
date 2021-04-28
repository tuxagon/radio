defmodule Radio.Spotify.TokenInfoTest do
  use ExUnit.Case, async: true
  doctest Radio.Spotify.TokenInfo

  @access_token "abc123"
  @refresh_token "xyz987"
  @expires_in "3600"
  @token_type "Bearer"

  @token_info %Radio.Spotify.TokenInfo{
    access_token: @access_token,
    refresh_token: @refresh_token,
    expires_in: @expires_in,
    token_type: @token_type
  }

  test "returns a tuple as an authorization header" do
    header = Radio.Spotify.TokenInfo.authorization_header(@token_info)

    assert {:Authorization, "#{@token_type} #{@access_token}"} == header
  end
end
