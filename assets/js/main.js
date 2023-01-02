import "../css/main.css";
import { Elm } from "../src/Main.elm";

const node = document.getElementById("elm");

const app = Elm.Main.init({
  node: node,
  flags: JSON.parse(node.dataset.flags),
});

app.ports.copyToClipboard.subscribe((text) =>
  navigator.clipboard.writeText(text)
);

app.ports.toggleModal.subscribe(() => {
  const modal = document.getElementById("modal");

  if (modal.open) {
    document.body.className = "";
    modal.close();
  } else {
    document.body.className = "noscroll";
    modal.showModal();
  }

  modal.addEventListener("close", (_) => (document.body.className = ""));
});
