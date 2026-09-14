# Guild Overseer — Bevy client

A skeleton. It draws the mockup's formation grid — three columns, two rows, two
sides — and pulses the squares so that "it is running" is visible rather than
inferred. There are no combat rules here; see [`../../docs`](../../docs) for
where those are meant to live.

Its job is to prove the deployment: that a Bevy app builds for wasm and ships
to GitHub Pages under `/bevy/` alongside the Flutter client at `/flutter/`.

## Toolchain

| | |
|---|---|
| Bevy | 0.19.1 |
| Rust | 1.95 or newer (Bevy 0.19's minimum) |

CI pins an exact stable in `.github/workflows/build.yml`, the same way the
Flutter version is pinned.

## Running it

```bash
cargo run                          # native window, debug
cargo run --release                # native window, release
```

On Linux this builds against X11, which winit loads at runtime. For Wayland,
add `"wayland"` to the native feature list in `Cargo.toml` — it needs
`libwayland-dev` (or your distribution's equivalent) installed to build, which
is why it is not on by default.

## Building for the web

Needs the wasm target and a `wasm-bindgen-cli` matching the `wasm-bindgen`
version in `Cargo.lock` — they are verified against each other and a mismatch
fails loudly:

```bash
rustup target add wasm32-unknown-unknown
cargo install wasm-bindgen-cli --version 0.2.128 --locked

cargo build --release --target wasm32-unknown-unknown
wasm-bindgen --no-typescript --target web \
  --out-dir dist \
  --out-name guild_overseer_bevy \
  target/wasm32-unknown-unknown/release/guild_overseer_bevy.wasm
cp web/index.html dist/

python3 -m http.server --directory dist 8080
```

`dist/` is what CI uploads and what Pages serves at `/bevy/`. Everything the
page references is relative, so it works at a domain root and in a
subdirectory without a build flag.

## Two things that are decided here rather than at deploy time

- **WebGL2, not WebGPU.** One wasm artifact cannot serve both, and WebGL2 runs
  in every current browser. The feature is set per-target in `Cargo.toml`.
- **Trimmed Bevy features.** The defaults carry PBR, glTF, audio and animation.
  A 2D client pays for all of them in build time and download size and uses
  none of them.
