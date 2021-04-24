const getToken = () => fetch("/token").then((response) => response.text());

onmessage = function (e) {
  getToken().then((token) => postMessage({ token }));
};
