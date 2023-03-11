import "../css/main.css";
import { Elm } from "../src/Main.elm";

const node = document.getElementById("elm");

const app = Elm.Main.init({
  node: node,
  flags: JSON.parse(node.dataset.flags),
});

app.ports.clearPath.subscribe(() => history.pushState({}, "", "/"));

app.ports.copyToClipboard.subscribe((text) =>
  navigator.clipboard.writeText(text)
);

app.ports.toggleModal.subscribe(() => {
  const getModal = (timeout) => {
    const helper = (resolve, reject) =>
      document.getElementById("modal")
        ? resolve(document.getElementById("modal"))
        : Date.now() < timeout
        ? setTimeout(helper, 100, resolve, reject)
        : reject(new Error("no modal"));

    return new Promise(helper);
  };

  getModal(Date.now() + 2000).then((modal) => {
    if (modal.open) {
      document.body.className = "";
      modal.close();
    } else {
      document.body.className = "noscroll";
      modal.showModal();
    }

    modal.addEventListener("close", (_) => (document.body.className = ""));
  });
});
