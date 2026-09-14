//! The strip along the top: where the party is in the dungeon, how long they
//! have been there, and the pause button.
//!
//! The row wraps rather than shrinks. At phone width the pips, the clock and
//! the button do not fit on one line, and a wrapped second line reads better
//! than a clock squeezed to three characters.

use bevy::prelude::*;

use super::theme;
use crate::run::{ROOM_COUNT, RunState};

/// One room in the progress strip; the index is which room it stands for.
#[derive(Component)]
pub struct RoomPip(usize);

/// The two pieces of text in this bar, named by what they say.
///
/// One component rather than two marker types on purpose: a system cannot hold
/// two `&mut Text` queries unless something makes them provably disjoint, and
/// an enum the query matches on is simpler than a pair of `Without` filters
/// that has to be kept in step by hand.
#[derive(Component, Clone, Copy, PartialEq, Eq)]
pub enum BarLabel {
    /// The run clock, which becomes the enrage countdown in the boss room.
    Clock,
    Pause,
}

#[derive(Component)]
pub struct PauseButton;

pub fn spawn(parent: &mut ChildSpawnerCommands) {
    parent
        .spawn(theme::panel(Node {
            flex_direction: FlexDirection::Row,
            align_items: AlignItems::Center,
            flex_wrap: FlexWrap::Wrap,
            column_gap: px(theme::GUTTER),
            row_gap: px(theme::GUTTER),
            padding: UiRect::axes(px(8), px(6)),
            ..default()
        }))
        .with_children(|bar| {
            bar.spawn(theme::label(
                "guild overseer",
                theme::SMALL,
                theme::TEXT_DIM,
            ));

            bar.spawn(Node {
                flex_direction: FlexDirection::Row,
                align_items: AlignItems::Center,
                column_gap: px(3),
                ..default()
            })
            .with_children(|pips| {
                for index in 0..ROOM_COUNT {
                    pips.spawn(pip(index));
                }
            });

            // An empty node that eats the slack, so everything after it sits
            // against the right-hand edge.
            bar.spawn(Node {
                flex_grow: 1.0,
                ..default()
            });

            bar.spawn((
                theme::label("0:00", theme::TITLE, theme::TEXT),
                BarLabel::Clock,
            ));
            bar.spawn(theme::button(
                "pause",
                theme::TRACK,
                PauseButton,
                BarLabel::Pause,
            ));
        });
}

/// A room, as a lozenge. The boss room is drawn wider, so "how far in are we"
/// and "which one is the boss" are the same glance.
fn pip(index: usize) -> impl Bundle {
    let boss = index + 1 == ROOM_COUNT;
    (
        Node {
            width: px(if boss { 22 } else { 13 }),
            height: px(5),
            border_radius: BorderRadius::all(px(2.5)),
            ..default()
        },
        BackgroundColor(theme::TRACK),
        RoomPip(index),
    )
}

pub fn toggle_pause(
    mut state: ResMut<RunState>,
    pressed: Query<&Interaction, (Changed<Interaction>, With<PauseButton>)>,
) {
    for interaction in &pressed {
        if *interaction == Interaction::Pressed {
            state.paused = !state.paused;
        }
    }
}

pub fn update(
    state: Res<RunState>,
    mut pips: Query<(&RoomPip, &mut BackgroundColor)>,
    mut labels: Query<(&BarLabel, &mut Text, &mut TextColor)>,
) {
    for (pip, mut colour) in &mut pips {
        let wanted = if pip.0 < state.room {
            theme::ACCENT.darker(0.22)
        } else if pip.0 == state.room {
            if state.boss_room() {
                theme::DANGER
            } else {
                theme::ACCENT
            }
        } else {
            theme::TRACK
        };
        // Assigned unconditionally this would mark the colour changed every
        // frame and re-extract the whole strip for nothing.
        if colour.0 != wanted {
            colour.0 = wanted;
        }
    }

    for (label, mut text, mut colour) in &mut labels {
        let (wanted, wanted_colour) = match label {
            BarLabel::Clock => match state.enrage_in() {
                Some(remaining) => (format!("enrage {}", minutes(remaining)), theme::DANGER),
                None => (minutes(state.elapsed), theme::TEXT),
            },
            BarLabel::Pause => {
                let word = if state.paused { "resume" } else { "pause" };
                (word.to_string(), theme::TEXT)
            }
        };

        if **text != wanted {
            **text = wanted;
        }
        if colour.0 != wanted_colour {
            colour.0 = wanted_colour;
        }
    }
}

fn minutes(seconds: f32) -> String {
    let seconds = seconds.max(0.0) as u32;
    format!("{}:{:02}", seconds / 60, seconds % 60)
}
