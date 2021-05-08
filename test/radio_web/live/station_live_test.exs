defmodule RadioWeb.StationLiveTest do
  use RadioWeb.ConnCase
  doctest RadioWeb.StationLive

  import Mox

  @station_name "test"
  @access_token "c28ab7e3-bfc8-42b5-bfaf-8d32353a6e57"
  @user %Radio.Spotify.User{id: "37b660b8-7525-4904-905a-e0fd09965603", name: "Test User"}
  @device %Radio.Spotify.Device{
    id: "30b88bf6-a8ac-438d-b0c3-d05b82d11464",
    name: "Test Device",
    type: "Computer"
  }
  @context %Radio.Context{
    user: @user,
    access_token: @access_token,
    selected_device: nil
  }

  setup :verify_on_exit!

  setup do
    Cachex.clear!(:context_cache)

    :ok
  end

  test "disconnected and connected mount", %{conn: conn} do
    Radio.ContextCache.put(@user.id, @context)

    expect(Radio.Spotify.MockApiClient, :get_my_devices, fn @access_token ->
      {:ok, [@device]}
    end)

    conn =
      conn
      |> put_session(:current_user_id, @user.id)
      |> get(Routes.station_path(conn, :index, @station_name))

    assert html_response(conn, 200) =~ "#{@station_name} radio"

    {:ok, _view, _html} = live(conn)
    assert @station_name == conn.assigns[:station_name]
    assert [] == conn.assigns[:devices]
    assert @user.id == conn.assigns[:current_user_id]
    assert @context == conn.assigns[:context]
    assert [] == conn.assigns[:current_queue]
    assert [] == conn.assigns[:upcoming_tracks]
  end
end
