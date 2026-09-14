//! The selected member's rotation, their target priority, and the retreat
//! button.
//!
//! The cooldown slot is the interesting one: a frame with a dark sweep behind
//! the text, its height the fraction of the cooldown still to run, so the slot
//! drains back to clear as the skill comes up. There are always [`MAX_SKILLS`]
//! slots, and the ones the current member has no skill for collapse out of the
//! layout rather than sitting there empty — which is `Display::None` doing
//! exactly what it does in CSS.

use bevy::prelude::*;

use super::theme;
use crate::run::{LogKind, MAX_SKILLS, RunState};

/// A slot, or the sweep drawn inside it. One component for both, because one
/// system resizes both and Bevy will not give a system two `&mut Node`
/// queries it cannot prove are disjoint.
#[derive(Component)]
pub enum SlotPart {
    Frame(usize),
    Sweep(usize),
}

/// Text that changes: a skill's name, its remaining cooldown, whose rotation
/// this is, and what the priority button currently says.
#[derive(Component)]
pub enum RotationLabel {
    Skill(usize),
    Cooldown(usize),
    Owner,
    Priority,
}

#[derive(Component)]
pub struct PriorityButton;

#[derive(Component)]
pub struct RetreatButton;

pub fn spawn(parent: &mut ChildSpawnerCommands) {
    parent
        .spawn(theme::panel(Node {
            flex_direction: FlexDirection::Row,
            align_items: AlignItems::Center,
            flex_wrap: FlexWrap::Wrap,
            column_gap: px(theme::GUTTER),
            row_gap: px(theme::GUTTER),
            padding: UiRect::all(px(6)),
            ..default()
        }))
        .with_children(|row| {
            row.spawn((
                theme::label("", theme::SMALL, theme::TEXT_DIM),
                RotationLabel::Owner,
            ));

            for slot in 0..MAX_SKILLS {
                row.spawn(slot_node(slot));
            }

            row.spawn(Node {
                flex_grow: 1.0,
                ..default()
            });

            row.spawn(theme::button(
                "nearest",
                theme::TRACK,
                PriorityButton,
                RotationLabel::Priority,
            ));
            row.spawn(theme::button(
                "retreat",
                theme::DANGER.darker(0.28),
                RetreatButton,
                (),
            ));
        });
}

fn slot_node(slot: usize) -> impl Bundle {
    (
        theme::panel_filled(
            Node {
                width: px(40),
                height: px(34),
                align_items: AlignItems::Center,
                justify_content: JustifyContent::Center,
                // The sweep is a child that fills from the bottom; without
                // this it would paint over the slot's rounded corners.
                overflow: Overflow::clip(),
                ..default()
            },
            // Lighter than the row behind it, so the sweep has something to
            // darken and a ready slot is bright rather than merely un-dimmed.
            theme::TRACK,
        ),
        SlotPart::Frame(slot),
        children![
            // Drawn first, so the labels below it stay readable: siblings later
            // in the list render on top.
            (
                Node {
                    position_type: PositionType::Absolute,
                    bottom: px(0),
                    left: px(0),
                    width: percent(100),
                    height: percent(0),
                    ..default()
                },
                BackgroundColor(theme::SWEEP),
                SlotPart::Sweep(slot),
            ),
            (
                Node {
                    flex_direction: FlexDirection::Column,
                    align_items: AlignItems::Center,
                    ..default()
                },
                children![
                    (
                        theme::label("", theme::SMALL, theme::TEXT),
                        RotationLabel::Skill(slot),
                    ),
                    (
                        theme::label("", theme::SMALL, theme::TEXT_DIM),
                        RotationLabel::Cooldown(slot),
                    ),
                ],
            ),
        ],
    )
}

pub fn cycle_priority(
    mut state: ResMut<RunState>,
    pressed: Query<&Interaction, (Changed<Interaction>, With<PriorityButton>)>,
) {
    for interaction in &pressed {
        if *interaction == Interaction::Pressed {
            let selected = state.selected;
            let member = &mut state.members[selected];
            member.priority = member.priority.next();

            let (name, priority) = (member.name, member.priority.label());
            state.push(LogKind::Notice, format!("{name} now targets {priority}."));
        }
    }
}

/// Retreating ends a run in the real game. Here it says so in the log and
/// stops the clock, which is as much as a skeleton can honestly claim.
pub fn retreat(
    mut state: ResMut<RunState>,
    pressed: Query<&Interaction, (Changed<Interaction>, With<RetreatButton>)>,
) {
    for interaction in &pressed {
        if *interaction == Interaction::Pressed && !state.paused {
            state.paused = true;
            state.push(LogKind::Notice, "The party retreats. Run over.".into());
        }
    }
}

pub fn update(
    state: Res<RunState>,
    mut parts: Query<(&SlotPart, &mut Node, &mut BorderColor)>,
    mut labels: Query<(&RotationLabel, &mut Text, &mut TextColor)>,
) {
    let member = state.selected();

    for (part, mut node, mut border) in &mut parts {
        match part {
            SlotPart::Frame(slot) => {
                let Some(skill) = member.skills.get(*slot) else {
                    if node.display != Display::None {
                        node.display = Display::None;
                    }
                    continue;
                };
                if node.display != Display::Flex {
                    node.display = Display::Flex;
                }

                // A ready skill is worth noticing across a whole row of slots,
                // and an edge carries further than a shade of grey.
                let wanted = if skill.remaining <= 0.0 {
                    theme::ACCENT
                } else {
                    theme::PANEL_EDGE
                };
                if border.top != wanted {
                    *border = BorderColor::all(wanted);
                }
            }
            SlotPart::Sweep(slot) => {
                let cooling = member
                    .skills
                    .get(*slot)
                    .map_or(0.0, |skill| skill.cooling());
                let height = percent(cooling * 100.0);
                if node.height != height {
                    node.height = height;
                }
            }
        }
    }

    for (label, mut text, mut colour) in &mut labels {
        let (wanted, wanted_colour) = match label {
            RotationLabel::Skill(slot) => match member.skills.get(*slot) {
                Some(skill) => (skill.name.to_string(), theme::TEXT),
                None => (String::new(), theme::TEXT),
            },
            RotationLabel::Cooldown(slot) => match member.skills.get(*slot) {
                // Rounded up: a slot showing "0" for the last second of a
                // cooldown is a slot lying about being ready.
                Some(skill) if skill.remaining > 0.0 => (
                    format!("{}s", skill.remaining.ceil() as u32),
                    theme::TEXT_DIM,
                ),
                _ => ("ready".to_string(), theme::ACCENT),
            },
            RotationLabel::Owner => (member.name.to_string(), theme::role_colour(member.role)),
            RotationLabel::Priority => (member.priority.label().to_string(), theme::TEXT),
        };

        if **text != wanted {
            **text = wanted;
        }
        if colour.0 != wanted_colour {
            colour.0 = wanted_colour;
        }
    }
}
