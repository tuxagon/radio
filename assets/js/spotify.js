const doFetch = (fetchFn) =>
  fetchFn()
    .then((response) => response.json())
    .catch((err) => {
      console.log(err);
    });

const csrfToken = () => document.querySelector("[name=csrf-token]").content;

const playOn = (device_id, stationName) =>
  doFetch(() =>
    fetch(`/api/play/${device_id}`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json",
        "x-csrf-token": csrfToken(),
      },
      body: JSON.stringify({ station_name: stationName }),
    })
  );

export { playOn };
