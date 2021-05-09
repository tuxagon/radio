defmodule Radio.Spotify.ApiClientTest do
  use ExUnit.Case, async: true
  import Mox

  alias Radio.Spotify.ApiClient, as: SpotifyApi

  @http_client Radio.HTTPClientMock
  @test_opts api_url: "api.spotify.com",
             redirect_url: "radio.dev/callback",
             token_url: "accounts.spotify.com/api/token"

  @auth_code_token_success_resp %{
    "access_token" => "c28ab7e3-bfc8-42b5-bfaf-8d32353a6e57",
    "expires_in" => 3600,
    "refresh_token" => "39ebc2ef-0b90-4a07-bf18-0af03fd5fb09",
    "scope" => "user-read-email",
    "token_type" => "Bearer"
  }

  @refresh_token_success_resp %{
    "access_token" => "c28ab7e3-bfc8-42b5-bfaf-8d32353a6e57",
    "token_type" => "Bearer",
    "expires_in" => 3600,
    "scope" => "user-read-email"
  }

  @client_credentials_token_success_resp %{
    "access_token" => "c28ab7e3-bfc8-42b5-bfaf-8d32353a6e57",
    "token_type" => "Bearer",
    "expires_in" => 3600
  }

  @my_devices_success_resp %{
    "devices" => [
      %{
        "id" => "fe98d116-af7a-4d20-9f42-4e749527c0c2",
        "is_active" => false,
        "is_private_session" => false,
        "is_restricted" => false,
        "name" => "Test Device",
        "type" => "Computer",
        "volume_percent" => 42
      }
    ]
  }

  @my_user_profile_success_resp %{
    "country" => "US",
    "display_name" => "tester",
    "email" => "tester@phxtest.com",
    "explicit_content" => %{
      "filter_enabled" => false,
      "filter_locked" => false
    },
    "external_urls" => %{
      "spotify" => "https://open.spotify.com/user/9cc11999-0ba0-4b5b-825c-3fa84abb0e4e"
    },
    "followers" => %{
      "href" => nil,
      "total" => 0
    },
    "href" => "https://api.spotify.com/v1/users/9cc11999-0ba0-4b5b-825c-3fa84abb0e4e",
    "id" => "9cc11999-0ba0-4b5b-825c-3fa84abb0e4e",
    "images" => [],
    "product" => "premium",
    "type" => "user",
    "uri" => "spotify:user:9cc11999-0ba0-4b5b-825c-3fa84abb0e4e"
  }

  @get_track_success_resp %{
    "album" => %{
      "album_type" => "album",
      "artists" => [
        %{
          "external_urls" => %{
            "spotify" => "https://open.spotify.com/artist/0gxyHStUsqpMadRV0Di1Qt"
          },
          "href" => "https://api.spotify.com/v1/artists/0gxyHStUsqpMadRV0Di1Qt",
          "id" => "0gxyHStUsqpMadRV0Di1Qt",
          "name" => "Rick Astley",
          "type" => "artist",
          "uri" => "spotify:artist:0gxyHStUsqpMadRV0Di1Qt"
        }
      ],
      "available_markets" => ["US"],
      "external_urls" => %{
        "spotify" => "https://open.spotify.com/album/5Z9iiGl2FcIfa3BMiv6OIw"
      },
      "href" => "https://api.spotify.com/v1/albums/5Z9iiGl2FcIfa3BMiv6OIw",
      "id" => "5Z9iiGl2FcIfa3BMiv6OIw",
      "images" => [
        %{
          "height" => 640,
          "url" => "https://i.scdn.co/image/ab67616d0000b2735755e164993798e0c9ef7d7a",
          "width" => 640
        },
        %{
          "height" => 300,
          "url" => "https://i.scdn.co/image/ab67616d00001e025755e164993798e0c9ef7d7a",
          "width" => 300
        },
        %{
          "height" => 64,
          "url" => "https://i.scdn.co/image/ab67616d000048515755e164993798e0c9ef7d7a",
          "width" => 64
        }
      ],
      "name" => "Whenever You Need Somebody",
      "release_date" => "1987-11-12",
      "release_date_precision" => "day",
      "total_tracks" => 10,
      "type" => "album",
      "uri" => "spotify:album:5Z9iiGl2FcIfa3BMiv6OIw"
    },
    "artists" => [
      %{
        "external_urls" => %{
          "spotify" => "https://open.spotify.com/artist/0gxyHStUsqpMadRV0Di1Qt"
        },
        "href" => "https://api.spotify.com/v1/artists/0gxyHStUsqpMadRV0Di1Qt",
        "id" => "0gxyHStUsqpMadRV0Di1Qt",
        "name" => "Rick Astley",
        "type" => "artist",
        "uri" => "spotify:artist:0gxyHStUsqpMadRV0Di1Qt"
      }
    ],
    "available_markets" => ["US"],
    "disc_number" => 1,
    "duration_ms" => 213_573,
    "explicit" => false,
    "external_ids" => %{
      "isrc" => "GBARL9300135"
    },
    "external_urls" => %{
      "spotify" => "https://open.spotify.com/track/4cOdK2wGLETKBW3PvgPWqT"
    },
    "href" => "https://api.spotify.com/v1/tracks/4cOdK2wGLETKBW3PvgPWqT",
    "id" => "4cOdK2wGLETKBW3PvgPWqT",
    "is_local" => false,
    "name" => "Never Gonna Give You Up",
    "popularity" => 76,
    "preview_url" =>
      "https://p.scdn.co/mp3-preview/0b6da17f858f104337fac626c4bac972d3947564?cid=b758794dbc8941c49a201d22b3f34d06",
    "track_number" => 1,
    "type" => "track",
    "uri" => "spotify:track:4cOdK2wGLETKBW3PvgPWqT"
  }

  @search_tracks_success_resp %{
    "tracks" => %{
      "href" =>
        "https://api.spotify.com/v1/search?query=Never+Gonna+Give+You+Up&type=track&offset=0&limit=1",
      "items" => [
        %{
          "album" => %{
            "album_type" => "album",
            "artists" => [
              %{
                "external_urls" => %{
                  "spotify" => "https://open.spotify.com/artist/0gxyHStUsqpMadRV0Di1Qt"
                },
                "href" => "https://api.spotify.com/v1/artists/0gxyHStUsqpMadRV0Di1Qt",
                "id" => "0gxyHStUsqpMadRV0Di1Qt",
                "name" => "Rick Astley",
                "type" => "artist",
                "uri" => "spotify:artist:0gxyHStUsqpMadRV0Di1Qt"
              }
            ],
            "available_markets" => ["US"],
            "external_urls" => %{
              "spotify" => "https://open.spotify.com/album/5Z9iiGl2FcIfa3BMiv6OIw"
            },
            "href" => "https://api.spotify.com/v1/albums/5Z9iiGl2FcIfa3BMiv6OIw",
            "id" => "5Z9iiGl2FcIfa3BMiv6OIw",
            "images" => [
              %{
                "height" => 640,
                "url" => "https://i.scdn.co/image/ab67616d0000b2735755e164993798e0c9ef7d7a",
                "width" => 640
              },
              %{
                "height" => 300,
                "url" => "https://i.scdn.co/image/ab67616d00001e025755e164993798e0c9ef7d7a",
                "width" => 300
              },
              %{
                "height" => 64,
                "url" => "https://i.scdn.co/image/ab67616d000048515755e164993798e0c9ef7d7a",
                "width" => 64
              }
            ],
            "name" => "Whenever You Need Somebody",
            "release_date" => "1987-11-12",
            "release_date_precision" => "day",
            "total_tracks" => 10,
            "type" => "album",
            "uri" => "spotify:album:5Z9iiGl2FcIfa3BMiv6OIw"
          },
          "artists" => [
            %{
              "external_urls" => %{
                "spotify" => "https://open.spotify.com/artist/0gxyHStUsqpMadRV0Di1Qt"
              },
              "href" => "https://api.spotify.com/v1/artists/0gxyHStUsqpMadRV0Di1Qt",
              "id" => "0gxyHStUsqpMadRV0Di1Qt",
              "name" => "Rick Astley",
              "type" => "artist",
              "uri" => "spotify:artist:0gxyHStUsqpMadRV0Di1Qt"
            }
          ],
          "available_markets" => ["US"],
          "disc_number" => 1,
          "duration_ms" => 213_573,
          "explicit" => false,
          "external_ids" => %{"isrc" => "GBARL9300135"},
          "external_urls" => %{
            "spotify" => "https://open.spotify.com/track/4cOdK2wGLETKBW3PvgPWqT"
          },
          "href" => "https://api.spotify.com/v1/tracks/4cOdK2wGLETKBW3PvgPWqT",
          "id" => "4cOdK2wGLETKBW3PvgPWqT",
          "is_local" => false,
          "name" => "Never Gonna Give You Up",
          "popularity" => 76,
          "preview_url" =>
            "https://p.scdn.co/mp3-preview/0b6da17f858f104337fac626c4bac972d3947564?cid=b758794dbc8941c49a201d22b3f34d06",
          "track_number" => 1,
          "type" => "track",
          "uri" => "spotify:track:4cOdK2wGLETKBW3PvgPWqT"
        }
      ],
      "limit" => 1,
      "next" =>
        "https://api.spotify.com/v1/search?query=Never+Gonna+Give+You+Up&type=track&offset=1&limit=1",
      "offset" => 0,
      "previous" => nil,
      "total" => 1857
    }
  }

  setup :verify_on_exit!

  setup do
    context = %{
      access_token: "353a6e80-09d2-4183-a98e-217c164ea997",
      device_id: "fe98d116-af7a-4d20-9f42-4e749527c0c2",
      refresh_token: "39ebc2ef-0b90-4a07-bf18-0af03fd5fb09",
      song_uri: "spotify:track:4cOdK2wGLETKBW3PvgPWqT",
      track_id: "4cOdK2wGLETKBW3PvgPWqT",
      search_term: "Never Gonna Give You Up"
    }

    {:ok, context}
  end

  describe "get_track" do
    test "returns track info for a successful response", %{track_id: track_id} do
      expect(@http_client, :post, fn "accounts.spotify.com/api/token", _body, _headers ->
        {:ok,
         %HTTPoison.Response{
           body: @client_credentials_token_success_resp |> Poison.encode!(),
           status_code: 200
         }}
      end)

      expect(@http_client, :get, fn "api.spotify.com/v1/tracks/" <> ^track_id, _headers ->
        {:ok,
         %HTTPoison.Response{
           body: @get_track_success_resp |> Poison.encode!(),
           status_code: 200
         }}
      end)

      expected_track_info = %Radio.Spotify.TrackInfo{
        duration_ms: 213_573,
        name: "Never Gonna Give You Up",
        uri: "spotify:track:4cOdK2wGLETKBW3PvgPWqT",
        artist_names: ["Rick Astley"]
      }

      resp = SpotifyApi.get_track(track_id, @test_opts)

      assert {:ok, expected_track_info} == resp
    end

    test "returns an error when fetching a track is not successful", _context do
      expect(@http_client, :post, fn "accounts.spotify.com/api/token", _body, _headers ->
        {:ok,
         %HTTPoison.Response{
           body: @client_credentials_token_success_resp |> Poison.encode!(),
           status_code: 200
         }}
      end)

      expect(@http_client, :get, fn "api.spotify.com/v1/tracks/unknown", _headers ->
        {:ok,
         %HTTPoison.Response{
           body:
             %{
               "error" => %{
                 "status" => 400,
                 "message" => "invalid id"
               }
             }
             |> Poison.encode!(),
           status_code: 400
         }}
      end)

      resp = SpotifyApi.get_track("unknown", @test_opts)

      assert {:error, %{message: "invalid id", status: 400}} == resp
    end

    test "returns an error when client credentials cannot be exchanged for an access token",
         %{track_id: track_id} do
      expect(@http_client, :post, fn "accounts.spotify.com/api/token", _body, _headers ->
        {:ok,
         %HTTPoison.Response{
           body:
             %{
               "error" => "invalid_client",
               "error_description" => "Invalid client"
             }
             |> Poison.encode!(),
           status_code: 400
         }}
      end)

      resp = SpotifyApi.get_track(track_id, @test_opts)

      assert {:error, %{message: "Invalid client", status: 400}} == resp
    end
  end

  describe "search_tracks" do
    test "returns tracks for a successful response", %{search_term: search_term} do
      params = %{q: search_term, type: "track", limit: 10, offset: 0} |> URI.encode_query()

      expect(@http_client, :post, fn "accounts.spotify.com/api/token", _body, _headers ->
        {:ok,
         %HTTPoison.Response{
           body: @client_credentials_token_success_resp |> Poison.encode!(),
           status_code: 200
         }}
      end)

      expect(@http_client, :get, fn "api.spotify.com/v1/search?" <> ^params, _headers ->
        {:ok,
         %HTTPoison.Response{
           body: @search_tracks_success_resp |> Poison.encode!(),
           status_code: 200
         }}
      end)

      expected_results = [
        %Radio.Spotify.TrackInfo{
          duration_ms: 213_573,
          name: "Never Gonna Give You Up",
          uri: "spotify:track:4cOdK2wGLETKBW3PvgPWqT",
          artist_names: ["Rick Astley"]
        }
      ]

      resp = SpotifyApi.search_tracks(search_term, 10, 0, @test_opts)

      assert {:ok, expected_results} == resp
    end

    test "returns an error when searching for tracks is not successful", _context do
      params = %{q: "", type: "track", limit: 10, offset: 0} |> URI.encode_query()

      expect(@http_client, :post, fn "accounts.spotify.com/api/token", _body, _headers ->
        {:ok,
         %HTTPoison.Response{
           body: @client_credentials_token_success_resp |> Poison.encode!(),
           status_code: 200
         }}
      end)

      expect(@http_client, :get, fn "api.spotify.com/v1/search?" <> ^params, _headers ->
        {:ok,
         %HTTPoison.Response{
           body:
             %{
               "error" => %{
                 "status" => 400,
                 "message" => "No search query"
               }
             }
             |> Poison.encode!(),
           status_code: 400
         }}
      end)

      resp = SpotifyApi.search_tracks("", 10, 0, @test_opts)

      assert {:error, %{message: "No search query", status: 400}} == resp
    end

    test "returns an error when client credentials cannot be exchanged for an access token",
         %{search_term: search_term} do
      expect(@http_client, :post, fn "accounts.spotify.com/api/token", _body, _headers ->
        {:ok,
         %HTTPoison.Response{
           body:
             %{
               "error" => "invalid_client",
               "error_description" => "Invalid client"
             }
             |> Poison.encode!(),
           status_code: 400
         }}
      end)

      resp = SpotifyApi.search_tracks(search_term, 10, 0, @test_opts)

      assert {:error, %{message: "Invalid client", status: 400}} == resp
    end
  end

  describe "get_my_devices" do
    test "returns a list of your devices for a successful response", %{access_token: access_token} do
      expect(@http_client, :get, fn "api.spotify.com/v1/me/player/devices",
                                    [{:Authorization, "Bearer " <> ^access_token} | _headers] ->
        {:ok,
         %HTTPoison.Response{body: @my_devices_success_resp |> Poison.encode!(), status_code: 200}}
      end)

      expected_devices = [
        %Radio.Spotify.Device{
          id: "fe98d116-af7a-4d20-9f42-4e749527c0c2",
          name: "Test Device",
          type: "Computer"
        }
      ]

      resp = SpotifyApi.get_my_devices(access_token, @test_opts)

      assert {:ok, expected_devices} == resp
    end

    test "returns an error when the access token is invalid", %{access_token: access_token} do
      expect(@http_client, :get, fn "api.spotify.com/v1/me/player/devices", _headers ->
        {:ok,
         %HTTPoison.Response{
           body:
             %{
               "error" => %{
                 "status" => 401,
                 "message" => "Invalid access token"
               }
             }
             |> Poison.encode!(),
           status_code: 401
         }}
      end)

      resp = SpotifyApi.get_my_devices(access_token, @test_opts)

      assert {:error, %{message: "Invalid access token", status: 401}} == resp
    end
  end

  describe "get_my_user" do
    test "returns your user for a successful response", %{access_token: access_token} do
      expect(@http_client, :get, fn "api.spotify.com/v1/me",
                                    [{:Authorization, "Bearer " <> ^access_token} | _headers] ->
        {:ok,
         %HTTPoison.Response{
           body: @my_user_profile_success_resp |> Poison.encode!(),
           status_code: 200
         }}
      end)

      expected_user = %Radio.Spotify.User{
        id: "9cc11999-0ba0-4b5b-825c-3fa84abb0e4e",
        name: "tester"
      }

      resp = SpotifyApi.get_my_user(access_token, @test_opts)

      assert {:ok, expected_user} == resp
    end

    test "returns an error when the access token is invalid", %{access_token: access_token} do
      expect(@http_client, :get, fn "api.spotify.com/v1/me", _headers ->
        {:ok,
         %HTTPoison.Response{
           body:
             %{
               "error" => %{
                 "status" => 401,
                 "message" => "Invalid access token"
               }
             }
             |> Poison.encode!(),
           status_code: 401
         }}
      end)

      resp = SpotifyApi.get_my_user(access_token, @test_opts)

      assert {:error, %{message: "Invalid access token", status: 401}} == resp
    end
  end

  describe "queue_track" do
    test "returns a successful response", %{access_token: access_token, song_uri: uri} do
      expect(@http_client, :post, fn "api.spotify.com/v1/me/player/queue?uri=" <> ^uri,
                                     nil,
                                     [{:Authorization, "Bearer " <> ^access_token} | _headers] ->
        {:ok, %HTTPoison.Response{body: nil, status_code: 204}}
      end)

      resp = SpotifyApi.queue_track(access_token, uri, @test_opts)

      assert {:ok, nil} == resp
    end

    test "returns an error when uri is bad", %{access_token: access_token, song_uri: uri} do
      expect(@http_client, :post, fn "api.spotify.com/v1/me/player/queue?uri=" <> ^uri,
                                     nil,
                                     [{:Authorization, "Bearer " <> ^access_token} | _headers] ->
        {:ok,
         %HTTPoison.Response{
           body:
             %{
               "error" => %{
                 "status" => 400,
                 "message" => "Invalid track uri: spotify:track:00GOPLxW4PGQuUYdPJh8K"
               }
             }
             |> Poison.encode!(),
           status_code: 400
         }}
      end)

      resp = SpotifyApi.queue_track(access_token, uri, @test_opts)

      assert {:error,
              %{message: "Invalid track uri: spotify:track:00GOPLxW4PGQuUYdPJh8K", status: 400}} ==
               resp
    end

    test "returns an error when the access token is invalid", %{
      access_token: access_token,
      song_uri: uri
    } do
      expect(@http_client, :post, fn "api.spotify.com/v1/me/player/queue?uri=" <> ^uri,
                                     nil,
                                     _headers ->
        {:ok,
         %HTTPoison.Response{
           body:
             %{
               "error" => %{
                 "status" => 401,
                 "message" => "Invalid access token"
               }
             }
             |> Poison.encode!(),
           status_code: 401
         }}
      end)

      resp = SpotifyApi.queue_track(access_token, uri, @test_opts)

      assert {:error, %{message: "Invalid access token", status: 401}} == resp
    end
  end

  describe "start_playblack" do
    test "returns a successful response", %{
      access_token: access_token,
      song_uri: uri,
      device_id: device_id
    } do
      expect(@http_client, :put, fn "api.spotify.com/v1/me/player/play?device_id=" <> ^device_id,
                                    _body,
                                    [{:Authorization, "Bearer " <> ^access_token} | _headers] ->
        {:ok, %HTTPoison.Response{body: nil, status_code: 204}}
      end)

      resp = SpotifyApi.start_playback(access_token, device_id, [uri], @test_opts)

      assert {:ok, nil} == resp
    end

    test "returns an error when uri is bad", %{
      access_token: access_token,
      song_uri: uri,
      device_id: device_id
    } do
      expect(@http_client, :put, fn "api.spotify.com/v1/me/player/play?device_id=" <> ^device_id,
                                    _body,
                                    [{:Authorization, "Bearer " <> ^access_token} | _headers] ->
        {:ok,
         %HTTPoison.Response{
           body:
             %{
               "error" => %{
                 "status" => 400,
                 "message" => "Invalid track uri: spotify:track:00GOPLxW4PGQuUYdPJh8K"
               }
             }
             |> Poison.encode!(),
           status_code: 400
         }}
      end)

      resp = SpotifyApi.start_playback(access_token, device_id, [uri], @test_opts)

      assert {:error,
              %{message: "Invalid track uri: spotify:track:00GOPLxW4PGQuUYdPJh8K", status: 400}} ==
               resp
    end

    test "returns an error when device is not found", %{
      access_token: access_token,
      song_uri: uri,
      device_id: device_id
    } do
      expect(@http_client, :put, fn "api.spotify.com/v1/me/player/play?device_id=" <> ^device_id,
                                    _body,
                                    [{:Authorization, "Bearer " <> ^access_token} | _headers] ->
        {:ok,
         %HTTPoison.Response{
           body:
             %{
               "error" => %{
                 "status" => 404,
                 "message" => "Device not found"
               }
             }
             |> Poison.encode!(),
           status_code: 404
         }}
      end)

      resp = SpotifyApi.start_playback(access_token, device_id, [uri], @test_opts)

      assert {:error, %{message: "Device not found", status: 404}} == resp
    end

    test "returns an error when the access token is invalid", %{
      access_token: access_token,
      song_uri: uri,
      device_id: device_id
    } do
      expect(@http_client, :put, fn "api.spotify.com/v1/me/player/play?device_id=" <> ^device_id,
                                    _body,
                                    [{:Authorization, "Bearer " <> ^access_token} | _headers] ->
        {:ok,
         %HTTPoison.Response{
           body:
             %{
               "error" => %{
                 "status" => 401,
                 "message" => "Invalid access token"
               }
             }
             |> Poison.encode!(),
           status_code: 401
         }}
      end)

      resp = SpotifyApi.start_playback(access_token, device_id, [uri], @test_opts)

      assert {:error, %{message: "Invalid access token", status: 401}} == resp
    end
  end

  describe "refresh_token" do
    test "returns a new access token on a successful response", %{refresh_token: refresh_token} do
      expect(@http_client, :post, fn "accounts.spotify.com/api/token", _body, _headers ->
        {:ok,
         %HTTPoison.Response{
           body: @refresh_token_success_resp |> Poison.encode!(),
           status_code: 200
         }}
      end)

      resp = SpotifyApi.refresh_token(refresh_token, @test_opts)

      assert {:ok,
              %{
                "access_token" => "c28ab7e3-bfc8-42b5-bfaf-8d32353a6e57",
                "expires_in" => 3600,
                "scope" => "user-read-email",
                "token_type" => "Bearer"
              }} = resp
    end

    test "returns an error when refresh token is invalid", _context do
      expect(@http_client, :post, fn "accounts.spotify.com/api/token", _body, _headers ->
        {:ok,
         %HTTPoison.Response{
           body:
             %{
               "error" => "invalid_grant",
               "error_description" => "Invalid refresh token"
             }
             |> Poison.encode!(),
           status_code: 400
         }}
      end)

      resp = SpotifyApi.refresh_token("unknown", @test_opts)

      assert {:error, %{message: "Invalid refresh token", status: 400}} == resp
    end
  end

  describe "exchange_auth_code_for_token" do
    test "returns token information on a successful exchange", _context do
      expect(@http_client, :post, fn "accounts.spotify.com/api/token", _body, _headers ->
        {:ok,
         %HTTPoison.Response{
           body: @auth_code_token_success_resp |> Poison.encode!(),
           status_code: 200
         }}
      end)

      resp = SpotifyApi.exchange_auth_code_for_token("good", @test_opts)

      assert {:ok,
              %{
                "access_token" => "c28ab7e3-bfc8-42b5-bfaf-8d32353a6e57",
                "expires_in" => 3600,
                "refresh_token" => "39ebc2ef-0b90-4a07-bf18-0af03fd5fb09",
                "scope" => "user-read-email",
                "token_type" => "Bearer"
              }} = resp
    end

    test "returns an error when the auth code is invalid", _context do
      expect(@http_client, :post, fn "accounts.spotify.com/api/token", _body, _headers ->
        {:ok,
         %HTTPoison.Response{
           body:
             %{
               "error" => "invalid_grant",
               "error_description" => "Invalid authorization code"
             }
             |> Poison.encode!(),
           status_code: 400
         }}
      end)

      resp = SpotifyApi.exchange_auth_code_for_token("bad", @test_opts)

      assert {:error, %{message: "Invalid authorization code", status: 400}} == resp
    end
  end
end
