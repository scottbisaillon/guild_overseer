//! The heads-up display.
//!
//! Widgets rather than a screen. Each one is something the game will need —
//! the list in `docs/ui/active-run.md` is where they come from — and each one
//! leans on a different corner of `bevy_ui`, so that "can we build this HUD in
//! `bevy_ui`" has an answer you can look at rather than argue about:
//!
//! | Widget | What it exercises |
//! |---|---|
//! | [`topbar`] | a wrapping flex row, per-frame text, a button that gates a system |
//! | [`roster`] | percentage-width fills, buttons made of nested nodes, selection |
//! | [`rotation`] | absolutely-positioned overlays, clipping, `Display::None` |
//! | [`combat_log`] | children spawned and despawned while the app runs |
//!
//! Everything they draw comes from [`crate::run::RunState`], which is a
//! stand-in. None of these widgets knows that, and none of them should: when a
//! real simulation publishes that resource instead, the HUD is already done.

mod combat_log;
mod roster;
mod rotation;
mod theme;
mod topbar;

use bevy::prelude::*;

use crate::run::{RunState, Tick};

pub struct HudPlugin;

impl Plugin for HudPlugin {
    fn build(&self, app: &mut App) {
        app.add_systems(Startup, spawn).add_systems(
            Update,
            (
                // Presses first, then the views that read what they wrote:
                // a button whose label lags a frame behind its own press is
                // the cheapest possible bug to avoid.
                (
                    topbar::toggle_pause,
                    roster::select,
                    rotation::cycle_priority,
                    rotation::retreat,
                ),
                (
                    topbar::update,
                    roster::update,
                    rotation::update,
                    combat_log::update,
                ),
                tint_buttons,
            )
                .chain()
                .after(Tick),
        );
    }
}

fn spawn(mut commands: Commands, state: Res<RunState>) {
    commands
        .spawn(Node {
            width: percent(100),
            height: percent(100),
            flex_direction: FlexDirection::Column,
            // Top bar against the top, everything else against the bottom,
            // with the arena visible through the gap between them.
            justify_content: JustifyContent::SpaceBetween,
            padding: UiRect::all(px(8)),
            row_gap: px(theme::GUTTER),
            ..default()
        })
        .with_children(|root| {
            topbar::spawn(root);

            root.spawn(Node {
                flex_direction: FlexDirection::Column,
                row_gap: px(theme::GUTTER),
                ..default()
            })
            .with_children(|bottom| {
                combat_log::spawn(bottom);
                rotation::spawn(bottom);
                roster::spawn(bottom, &state);
            });
        });
}

/// Hover and press feedback for every button that carries a [`theme::Tint`].
///
/// One system for all of them rather than a branch inside each button's own
/// handler: feedback is what separates a button from a rectangle, and it
/// should not be something a new button can forget to implement.
fn tint_buttons(
    mut buttons: Query<(&Interaction, &theme::Tint, &mut BackgroundColor), Changed<Interaction>>,
) {
    for (interaction, tint, mut colour) in &mut buttons {
        colour.0 = tint.of(*interaction);
    }
}
