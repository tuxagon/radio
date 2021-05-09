defmodule TrackSearchComponent do
  use RadioWeb, :live_component

  alias Radio.Stations

  @impl true
  def render(assigns) do
    input_border_rounding =
      if assigns[:search_results], do: "rounded-tl-3xl rounded-tr-3xl", else: "rounded-3xl"

    ~L"""
    <div id="<%= @id %>" class="container p-10">
      <form autocomplete="off" phx-change="search" phx-target="<%= @myself %>">
        <div class="autocomplete">
          <input type="text" name="search_term" placeholder="Search" autocomplete="off" phx-debounce="300"
            class="<%= input_border_rounding %> px-5 py-3 text-lg w-full outline-none border border-black focus:border-spotify-green"
          />
          <%= if assigns[:search_results] do %>
            <div class="border-l border-r border-b border-spotify-green">
              <ul>
                <%= Enum.map(@search_results, fn %{name: name, album: album, artist_names: artists, uri: uri} -> %>
                  <li phx-click="queue" phx-target="<%= @myself %>" phx-throttle="300" phx-value-uri="<%= uri %>" phx-value-station="<%= @station_name %>"
                    class="flex flex-row p-1 bg-gray-50 items-center last:border-b-0 border-b border-gray-300 cursor-pointer"
                  >
                    <div class="w-20 mr-2">
                      <img src="<%= album.image_url %>" />
                    </div>
                    <div class="flex flex-col">
                      <p class="text-lg">
                        <strong><%= name %></strong>
                      </p>
                      <p class="text-sm"><%= Enum.join(artists, ", ") %></p>
                      <p class="text-sm"><%= album.name %></p>
                    </div>
                  </li>
                <% end) %>
              </ul>
            </div>
          <% end %>
        </div>
      </form>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def handle_event("search", %{"search_term" => search_term}, socket) do
    case Stations.find_tracks_by(search_term) do
      [] ->
        {:noreply, assign(socket, search_results: nil)}

      results ->
        {:noreply, assign(socket, search_results: results)}
    end
  end

  @impl true
  def handle_event("queue", %{"uri" => track_uri, "station" => station_name}, socket) do
    Stations.queue_track(station_name, track_uri)

    {:noreply, assign(socket, search_results: nil)}
  end
end
