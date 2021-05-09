defmodule Radio.Stations do
  alias Radio.Spotify

  defp spotify_api_client, do: Application.get_env(:radio, :spotify_api_client)

  def find_tracks_by("spotify:track:" <> search_term) do
    search_term
    |> spotify_api_client().get_track()
    |> (fn result ->
          case result do
            {:ok, track} ->
              [track]

            _error ->
              []
          end
        end).()
  end

  def find_tracks_by(search_term) do
    cond do
      Spotify.song_link?(search_term) ->
        search_term
        |> Spotify.track_id_from_song_link()
        |> (fn track_id ->
              find_tracks_by("spotify:track:#{track_id}")
            end).()

      true ->
        search_term
        |> spotify_api_client().search_tracks(5, 0)
        |> (fn result ->
              case result do
                {:ok, tracks} ->
                  tracks

                _error ->
                  []
              end
            end).()
    end
  end

  def queue_track(station_name, "spotify:track:" <> track_id),
    do: Radio.StationRegistry.queue_track(station_name, track_id)

  def queue_track(_station_name, _track_uri), do: nil
end
