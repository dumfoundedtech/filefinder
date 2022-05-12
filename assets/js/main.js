import "../css/main.css";
import { Elm } from "../src/Main.elm";

const node = document.getElementById("elm");

const app = Elm.Main.init({
  node: node,
  flags: JSON.parse(node.dataset.flags),
});

app.ports.copyToClipboard.subscribe((text) => console.log(text));