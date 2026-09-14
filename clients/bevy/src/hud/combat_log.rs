//! The combat log: the last few things that happened, newest at the bottom.
//!
//! Every other widget here edits nodes that already exist. This one spawns and
//! despawns them while the app runs, which is the other half of what a HUD
//! needs `bevy_ui` to survive — and the reason the panel is a fixed height
//! with `Overflow::clip`: lines leave by being scrolled off the top, not by
//! pushing the roster off the bottom.

use bevy::prelude::*;

use super::theme;
use crate::run::{LogLine, RunState};

/// Lines kept on screen. The rest are still in [`RunState`]; they are just
/// above the top edge of the panel.
const VISIBLE: usize = 5;

/// The panel, and the log revision it is currently showing.
#[derive(Component)]
pub struct LogPanel {
    shown: u64,
}

pub fn spawn(parent: &mut ChildSpawnerCommands) {
    parent.spawn((
        theme::panel(Node {
            flex_direction: FlexDirection::Column,
            // Newest at the bottom, the way a terminal does it: the column
            // grows upward out of the clipped top edge.
            justify_content: JustifyContent::FlexEnd,
            height: px(64),
            padding: UiRect::axes(px(8), px(5)),
            row_gap: px(1),
            overflow: Overflow::clip(),
            ..default()
        }),
        LogPanel { shown: 0 },
    ));
}

pub fn update(
    mut commands: Commands,
    state: Res<RunState>,
    mut panel: Query<(Entity, &mut LogPanel)>,
) {
    let Ok((entity, mut view)) = panel.single_mut() else {
        return;
    };

    // The queue is bounded, so its length stops changing once it is full and
    // cannot be used to notice a new line. The revision can.
    if view.shown == state.log_seq {
        return;
    }
    view.shown = state.log_seq;

    // Rebuilt rather than appended: five rows is cheap, and a rebuild has no
    // second code path to get wrong when lines age off the top.
    commands
        .entity(entity)
        .despawn_children()
        .with_children(|panel| {
            let older = state.log.len().saturating_sub(VISIBLE);
            for line in state.log.iter().skip(older) {
                panel.spawn(row(line));
            }
        });
}

fn row(line: &LogLine) -> impl Bundle {
    let at = line.at.max(0.0) as u32;
    (
        Node {
            flex_direction: FlexDirection::Row,
            column_gap: px(5),
            ..default()
        },
        children![
            theme::label(
                format!("{}:{:02}", at / 60, at % 60),
                theme::SMALL,
                theme::TEXT_DIM,
            ),
            theme::label(
                line.text.clone(),
                theme::SMALL,
                theme::log_colour(line.kind),
            ),
        ],
    )
}
