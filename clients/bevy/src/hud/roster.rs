//! The party roster: one card per member, along the bottom.
//!
//! Each card is three readings of the same member — a health bar, a fatigue
//! bar under it, and a line of text saying what they are doing — and the whole
//! card is a button, because the roster doubles as the member tab switcher
//! that `docs/ui/active-run.md` asks for. Tapping a card is how the rotation
//! row below learns whose cooldowns to draw.

use bevy::prelude::*;

use super::theme;
use crate::run::{Member, RunState};

/// The card as a whole, and the member it belongs to.
#[derive(Component)]
pub struct MemberCard(usize);

/// A bar's fill. Both bars on a card are resized by one system, so both carry
/// the same component and say which they are — two marker types would need two
/// `&mut Node` queries, which Bevy will not hand to one system.
#[derive(Component)]
pub struct Fill {
    member: usize,
    kind: Bar,
}

#[derive(Clone, Copy, PartialEq, Eq)]
pub enum Bar {
    Health,
    Fatigue,
}

/// A card's text, for the same reason.
#[derive(Component)]
pub struct CardLabel {
    member: usize,
    kind: Line,
}

#[derive(Clone, Copy, PartialEq, Eq)]
pub enum Line {
    /// The health percentage, top right.
    Health,
    /// Role and what they are doing, under the bars.
    Status,
}

pub fn spawn(parent: &mut ChildSpawnerCommands, state: &RunState) {
    parent
        .spawn(Node {
            flex_direction: FlexDirection::Row,
            column_gap: px(theme::GUTTER),
            ..default()
        })
        .with_children(|row| {
            for (index, member) in state.members.iter().enumerate() {
                row.spawn(card(index, member));
            }
        });
}

fn card(index: usize, member: &Member) -> impl Bundle {
    (
        Button,
        theme::panel(Node {
            flex_direction: FlexDirection::Column,
            row_gap: px(3),
            padding: UiRect::all(px(5)),
            // Equal shares of the row, and `min_width` undoes flexbox's
            // refusal to shrink a child below its text: without it four cards
            // push each other off a phone-width screen.
            flex_grow: 1.0,
            flex_basis: px(0),
            min_width: px(0),
            ..default()
        }),
        theme::Tint::new(theme::PANEL),
        MemberCard(index),
        children![
            (
                Node {
                    flex_direction: FlexDirection::Row,
                    align_items: AlignItems::Center,
                    column_gap: px(3),
                    ..default()
                },
                children![
                    theme::label(member.name, theme::BODY, theme::role_colour(member.role)),
                    Node {
                        flex_grow: 1.0,
                        ..default()
                    },
                    (
                        theme::label("100%", theme::SMALL, theme::TEXT_DIM),
                        CardLabel {
                            member: index,
                            kind: Line::Health,
                        },
                    ),
                ],
            ),
            theme::bar(
                5.0,
                theme::HEAL,
                Fill {
                    member: index,
                    kind: Bar::Health,
                },
            ),
            theme::bar(
                2.0,
                theme::WARN,
                Fill {
                    member: index,
                    kind: Bar::Fatigue,
                },
            ),
            (
                theme::label(member.role.label(), theme::SMALL, theme::TEXT_DIM),
                CardLabel {
                    member: index,
                    kind: Line::Status,
                },
            ),
        ],
    )
}

pub fn select(
    mut state: ResMut<RunState>,
    pressed: Query<(&Interaction, &MemberCard), Changed<Interaction>>,
) {
    for (interaction, card) in &pressed {
        if *interaction == Interaction::Pressed {
            state.selected = card.0;
        }
    }
}

pub fn update(
    state: Res<RunState>,
    mut cards: Query<(&MemberCard, &mut BorderColor)>,
    mut fills: Query<(&Fill, &mut Node, &mut BackgroundColor)>,
    mut labels: Query<(&CardLabel, &mut Text, &mut TextColor)>,
) {
    // The selected card is the one the rotation row is about, so it is worth a
    // whole border rather than a tint that hover would drown out.
    for (card, mut border) in &mut cards {
        let wanted = if card.0 == state.selected {
            theme::ACCENT
        } else {
            theme::PANEL_EDGE
        };
        if border.top != wanted {
            *border = BorderColor::all(wanted);
        }
    }

    for (fill, mut node, mut colour) in &mut fills {
        let Some(member) = state.members.get(fill.member) else {
            continue;
        };

        let (fraction, wanted) = match fill.kind {
            Bar::Health => (member.health, theme::health_colour(member.health)),
            Bar::Fatigue => (member.fatigue, theme::WARN),
        };

        let width = percent(fraction.clamp(0.0, 1.0) * 100.0);
        if node.width != width {
            node.width = width;
        }
        if colour.0 != wanted {
            colour.0 = wanted;
        }
    }

    for (label, mut text, mut colour) in &mut labels {
        let Some(member) = state.members.get(label.member) else {
            continue;
        };

        let (wanted, wanted_colour) = match label.kind {
            Line::Health => (
                format!("{}%", (member.health * 100.0).round() as u32),
                theme::TEXT_DIM,
            ),
            Line::Status => (
                format!("{} / {}", member.role.label(), member.status.label()),
                theme::status_colour(member.status),
            ),
        };

        if **text != wanted {
            **text = wanted;
        }
        if colour.0 != wanted_colour {
            colour.0 = wanted_colour;
        }
    }
}
