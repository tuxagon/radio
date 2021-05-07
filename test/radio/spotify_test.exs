defmodule Radio.SpotifyTest do
  use ExUnit.Case, async: true

  @client_id "d71248e8-a64c-4f10-9ab4-24332faf9353"
  @redirect_uri "radio.dev/callback"
  @authorize_url "https://accounts.spotify.com/authorize"
  @test_opts [authorize_url: @authorize_url, redirect_uri: @redirect_uri, client_id: @client_id]

  describe "authorize_url" do
    setup do
      {url, state} = Radio.Spotify.authorize_url(@test_opts)

      %{uri: URI.parse(url), state: state}
    end

    test "host", %{uri: %{host: host}} do
      assert "accounts.spotify.com" == host
    end

    test "path", %{uri: %{path: path}} do
      assert "/authorize" == path
    end

    test "query", %{uri: %{query: query}, state: state} do
      assert %{
               "client_id" => @client_id,
               "redirect_uri" => @redirect_uri,
               "response_type" => "code",
               "scope" => Radio.Spotify.scopes() |> Enum.join(" "),
               "state" => state
             } == URI.decode_query(query)
    end
  end

  describe "track_id_from_song_link" do
    test "extracts track id for a valid song link" do
      song_link = "https://open.spotify.com/track/4cOdK2wGLETKBW3PvgPWqT?si=4954eec923ed4eca"

      track_id = Radio.Spotify.track_id_from_song_link(song_link)

      assert "4cOdK2wGLETKBW3PvgPWqT" == track_id
    end

    test "returns nil for invalid song link" do
      song_link = "invalid"

      track_id = Radio.Spotify.track_id_from_song_link(song_link)

      assert nil == track_id
    end
  end

  describe "valid_song_link?" do
    test "returns true when valid" do
      song_link = "https://open.spotify.com/track/4cOdK2wGLETKBW3PvgPWqT?si=4954eec923ed4eca"

      assert true == Radio.Spotify.valid_song_link?(song_link)
    end

    test "returns false when invalid" do
      song_link = "invalid"

      assert false == Radio.Spotify.valid_song_link?(song_link)
    end
  end
end
