defmodule Radio.ContextTest do
  use ExUnit.Case, async: true
  doctest Radio.Context

  @user %Radio.Spotify.User{
    id: "68490237-d9cc-4b28-9bf2-a2ccf60d2b8b",
    name: "Test"
  }
  @access_token "3261e824-d9bf-4453-a682-34f25839fdb3"
  @device %Radio.Spotify.Device{
    id: "8db896f2-9250-43ef-8bbc-e24990574c5e",
    name: "Test Device",
    type: "Computer"
  }

  test "sets a context's :selected_device field to the new device" do
    pre_context = %Radio.Context{
      user: @user,
      access_token: @access_token
    }

    context = Radio.Context.select_device(pre_context, @device)

    assert %Radio.Context{
             user: @user,
             access_token: @access_token,
             selected_device: @device
           } == context
  end

  test "sets a context's :selected_device field to be nil" do
    pre_context = %Radio.Context{
      user: @user,
      access_token: @access_token,
      selected_device: @device
    }

    context = Radio.Context.deselect_device(pre_context)

    assert %Radio.Context{user: @user, access_token: @access_token} == context
  end
end
