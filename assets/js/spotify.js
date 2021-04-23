window.onSpotifyWebPlaybackSDKReady = () => {
  const token = localStorage.getItem("spotifyAccessToken");

  const player = new Spotify.Player({
    name: "Web Playback SDK Quick Start Player",
  });

  const play = ({
    spotify_uri,
    playerInstance: {
      _options: { getOAuthToken, id },
    },
  }) => {
    getOAuthToken((access_token) => {
      fetch(`https://api.spotify.com/v1/me/player/play?device_id=${id}`, {
        method: "PUT",
        body: JSON.stringify({ uris: [spotify_uri] }),
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${token}`,
        },
      });
    });
  };

  //   const player = new Spotify.Player({
  //     name: "Web Playback SDK Quick Start Player",
  //     getOAuthToken: (cb) => {
  //       cb(token);
  //     },
  //   });

  // Error handling
  player.addListener("initialization_error", ({ message }) => {
    console.error(message);
  });
  player.addListener("authentication_error", ({ message }) => {
    console.error(message);
  });
  player.addListener("account_error", ({ message }) => {
    console.error(message);
  });
  player.addListener("playback_error", ({ message }) => {
    console.error(message);
  });

  // Playback status updates
  player.addListener("player_state_changed", (state) => {
    console.log(state);
  });

  // Ready
  player.addListener("ready", ({ device_id }) => {
    console.log("Ready with Device ID", device_id);
  });

  // Not Ready
  player.addListener("not_ready", ({ device_id }) => {
    console.log("Device ID has gone offline", device_id);
  });

  play({
    playerInstance: new Spotify.Player({ name: "..." }),
    spotify_uri: "spotify:track:7xGfFoTpQ2E7fRF5lN10tr",
  });

  //   // Connect to the player!
  //   player.connect().then((success) => {
  //     if (success) {
  //       console.log("The Web Playback SDK successfully connected to Spotify!");
  //     }
  //   });
};
