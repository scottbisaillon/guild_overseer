# Guild Overseer — Bevy client

A skeleton. It draws the mockup's formation grid — three columns, two rows, two
sides — pulses the squares so that "it is running" is visible rather than
inferred, and hangs a HUD over the top of it. There are no combat rules here;
see [`../../docs`](../../docs) for where those are meant to live.

Its job is to prove two things. First the deployment: that a Bevy app builds
for wasm and ships to GitHub Pages under `/bevy/` alongside the Flutter client
at `/flutter/`. Second the toolkit: that `bevy_ui` can carry the HUD
[`docs/ui/active-run.md`](../../docs/ui/active-run.md) describes, on a phone as
well as on a desktop.

## What is on screen

Four widgets, each one a thing the real game needs and each one leaning on a
different corner of `bevy_ui`. They are useful in themselves and they are also
the test: if one of them could not be built this way, better to find out now.

| Widget | What it does | What it exercises |
|---|---|---|
| **Room strip** | Progress through the dungeon, the boss room marked wider, a clock that becomes the enrage countdown once the boss room starts. **Pause** freezes the run and the arena's pulse with it. | A flex row that wraps at phone width, text rewritten per frame, a button that gates other systems through a run condition. |
| **Party roster** | One card per member: health bar, fatigue bar under it, role and current status. Tapping a card selects that member — the roster doubles as the member tab switcher. | Percentage-width fills inside clipped tracks, equal-share flex columns that survive a 390px canvas, buttons built out of nested nodes. |
| **Rotation row** | The selected member's cooldowns, a dark sweep draining out of each slot as its cooldown runs down, and an outline when it is ready. **Target priority** cycles nearest → weakest → threat → strongest → manual. **Retreat** stops the run and says so in the log — as much as a skeleton can honestly do. | Absolutely-positioned overlays inside a clipped parent, `Display::None` collapsing the slots a shorter rotation does not use, sibling draw order. |
| **Combat log** | The last few damage, heal, skill and loot lines, newest at the bottom, colour-coded by kind. | Children spawned and despawned while the app runs, and a fixed-height panel that clips rather than grows. |

None of this is a simulation. The widgets read a resource in
[`src/run.rs`](src/run.rs) that drains health, spins cooldowns and walks the
party through rooms on a timer — a puppet, deliberately, so that every widget
can be seen working. When the real rules crate arrives it publishes a resource
in that shape and the HUD does not change.

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
