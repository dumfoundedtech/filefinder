const esbuild = require("esbuild");
const ElmPlugin = require("esbuild-plugin-elm");

const args = process.argv.slice(2);
const watch = args.includes("--watch");
const deploy = args.includes("--deploy");

const loader = {};

const elmOpts = watch
  ? { debug: true, clearOnWatch: true }
  : deploy
  ? { optimize: true }
  : {};

const plugins = [ElmPlugin(elmOpts)];

let opts = {
  entryPoints: ["js/app.js", "js/main.js"],
  bundle: true,
  target: "es2017",
  outdir: "../priv/static/assets",
  logLevel: "info",
  loader,
  plugins,
};

if (watch) {
  opts = {
    ...opts,
    watch,
    sourcemap: "inline",
  };
}

if (deploy) {
  opts = {
    ...opts,
    minify: true,
  };
}

const promise = esbuild.build(opts);

if (watch) {
  promise.then((_result) => {
    process.stdin.on("close", () => {
      process.exit(0);
    });

    process.stdin.resume();
  });
}
