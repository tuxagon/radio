// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.scss";

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
//     import socket from "./socket"
//
import "phoenix_html";
import { Socket } from "phoenix";
import topbar from "topbar";
import { LiveSocket } from "phoenix_live_view";
import { playOn } from "./spotify";

const channelToken = document
  .querySelector("meta[name=channel_token]")
  .getAttribute("content");

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");

const tokenWorker = new Worker("/js/worker.js");

let Hooks = {};
Hooks.PlayOn = {
  mounted() {
    this.el.addEventListener("click", (e) => {
      const { deviceId, deviceName, stationName } = e.target.dataset;

      playOn(deviceId, stationName);
      this.pushEvent("set-device", {
        device_id: deviceId,
        device_name: deviceName,
      });
    });
  },
};

let liveSocket = new LiveSocket("/live", Socket, {
  hooks: Hooks,
  params: { _csrf_token: csrfToken },
});

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (info) => topbar.show());
window.addEventListener("phx:page-loading-stop", (info) => topbar.hide());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;

const socket = new Socket("/socket", { params: { token: channelToken } });
socket.connect();

const listenForAccessToken = (user_id) => {
  let channel = socket.channel(`token:${user_id}`);

  channel
    .join(`token:${user_id}`)
    .receive("ok", (resp) => {
      console.log("Listening for access tokens", resp);
    })
    .receive("error", (resp) => {
      console.log("Unable to listen for access tokens", resp);
    });

  channel.on("refreshed", (payload) => {
    console.log(payload);
  });
};

let channel = socket.channel("token:all", {});
channel
  .join()
  .receive("ok", (user_id) => {
    listenForAccessToken(user_id);
    console.log("Joined successfully", user_id);
  })
  .receive("error", (resp) => {
    console.log("Unable to join", resp);
  });
