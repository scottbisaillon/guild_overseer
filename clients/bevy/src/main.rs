//! The Bevy client, as a skeleton.
//!
//! This exists to prove things end to end: that a Bevy app builds for wasm,
//! deploys to GitHub Pages under `/bevy/`, and runs there beside the Flutter
//! client at `/flutter/` — and that `bevy_ui` can carry the HUD the game
//! needs, at phone width as well as on a desktop.
//!
//! It holds no combat rules and is not a port of anything. [`arena`] draws the
//! mockup's formation so that "it rendered" is obvious at a glance, [`hud`]
//! draws widgets the real game will want, and [`run`] is the puppet they read
//! from until there is something real to read.
//!
//! See `docs/architecture/` for where the rules are meant to live: a separate
//! crate with no Bevy dependency, driven by this one.

mod arena;
mod hud;
mod run;

use bevy::prelude::*;

fn main() {
    App::new()
        .add_plugins(DefaultPlugins.set(WindowPlugin {
            primary_window: Some(Window {
                title: "Guild Overseer - Bevy client".into(),
                // The page owns the canvas so the loading text can be replaced
                // rather than sharing the document with a canvas Bevy appends.
                canvas: Some("#bevy-canvas".into()),
                fit_canvas_to_parent: true,
                // The canvas keeps its own gestures. Left to the browser, a
                // swipe on a phone scrolls the page and pulls to refresh
                // rather than reaching the app at all.
                prevent_default_event_handling: true,
                ..default()
            }),
            ..default()
        }))
        .insert_resource(ClearColor(Color::srgb(0.07, 0.08, 0.11)))
        // `run` first: it owns the state the other two read, and a plugin that
        // reads a resource on startup wants it to exist by then.
        .add_plugins((run::RunPlugin, arena::ArenaPlugin, hud::HudPlugin))
        .run();
}
