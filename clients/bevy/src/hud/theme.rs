//! Colours, sizes, and the three or four shapes every widget in the HUD is
//! built out of.
//!
//! A HUD made of one-off nodes drifts: two panels with different corner radii
//! and three greys that were each "close enough" at the time. The helpers here
//! are deliberately small — a slab, a label, a fraction bar — because their job
//! is consistency, not abstraction.

use bevy::prelude::*;

use crate::run::{LogKind, Role, Status};

/// The HUD sits over a dark arena, so its panels are darker still and slightly
/// transparent: legible, without hiding what is underneath.
pub const PANEL: Color = Color::srgba(0.09, 0.10, 0.14, 0.86);
pub const PANEL_EDGE: Color = Color::srgb(0.19, 0.22, 0.30);
pub const TRACK: Color = Color::srgb(0.16, 0.18, 0.24);
pub const SWEEP: Color = Color::srgba(0.03, 0.04, 0.06, 0.78);

pub const TEXT: Color = Color::srgb(0.84, 0.87, 0.93);
pub const TEXT_DIM: Color = Color::srgb(0.50, 0.55, 0.65);

/// The party blue and dungeon red the arena already uses. Reusing them is what
/// makes the HUD read as part of the same screen.
pub const ACCENT: Color = Color::srgb(0.35, 0.62, 0.86);
pub const DANGER: Color = Color::srgb(0.84, 0.36, 0.38);
pub const HEAL: Color = Color::srgb(0.40, 0.76, 0.54);
pub const WARN: Color = Color::srgb(0.90, 0.70, 0.33);

/// Three sizes, not a scale. A phone canvas is ~390 logical pixels wide and
/// anything larger than this crowds four member cards off the screen.
pub const TITLE: f32 = 13.0;
pub const BODY: f32 = 11.0;
pub const SMALL: f32 = 9.0;

/// The gap and corner radius every panel shares.
pub const GUTTER: f32 = 6.0;
pub const RADIUS: f32 = 5.0;

pub fn role_colour(role: Role) -> Color {
    match role {
        Role::Tank => ACCENT,
        Role::Healer => HEAL,
        Role::MeleeDps => WARN,
        Role::RangedDps => Color::srgb(0.70, 0.56, 0.88),
    }
}

/// Health is a fraction, and the colour is how urgently to read it.
pub fn health_colour(fraction: f32) -> Color {
    if fraction < 0.3 {
        DANGER
    } else if fraction < 0.6 {
        WARN
    } else {
        HEAL
    }
}

pub fn status_colour(status: Status) -> Color {
    match status {
        Status::Seeking => TEXT_DIM,
        Status::Firing => ACCENT,
        Status::Stunned => DANGER,
    }
}

pub fn log_colour(kind: LogKind) -> Color {
    match kind {
        LogKind::Damage => DANGER,
        LogKind::Heal => HEAL,
        LogKind::Skill => TEXT,
        LogKind::Loot => WARN,
        LogKind::Notice => TEXT_DIM,
    }
}

/// A dark rounded slab with a hairline edge: the shape every HUD box shares.
///
/// Takes the caller's [`Node`] and fills in only the parts that make it a
/// panel, so a caller still owns its own layout.
pub fn panel(node: Node) -> impl Bundle {
    panel_filled(node, PANEL)
}

/// The same slab in a colour of its own, for a panel something is drawn
/// *over*: a cooldown sweep against the standard panel colour is two shades of
/// near-black and reads as nothing at all.
pub fn panel_filled(node: Node, background: Color) -> impl Bundle {
    (
        Node {
            border: UiRect::all(px(1)),
            border_radius: BorderRadius::all(px(RADIUS)),
            ..node
        },
        BackgroundColor(background),
        BorderColor::all(PANEL_EDGE),
    )
}

/// Text at a size and a colour, with everything else left at its default.
///
/// Every string that reaches this function has to be ASCII. Bevy's default
/// font is a 96-glyph subset of Fira Mono with nothing above `~` in it, so a
/// middle dot, an em dash or an arrow renders as a tofu box. Comments and
/// documentation are free to use them; labels are not.
pub fn label(text: impl Into<String>, size: f32, colour: Color) -> impl Bundle {
    (
        Text::new(text),
        TextFont {
            font_size: FontSize::Px(size),
            ..default()
        },
        TextColor(colour),
    )
}

/// A fraction drawn as a bar: a sunken track with a fill that the caller's
/// marker component lets a system resize later.
///
/// The fill starts full width; the systems in [`super::roster`] write the
/// fraction every frame, and a bar nobody updates is simply a full one.
pub fn bar(height: f32, colour: Color, fill_marker: impl Bundle) -> impl Bundle {
    (
        Node {
            width: percent(100),
            height: px(height),
            border_radius: BorderRadius::all(px(height / 2.0)),
            // Without this the fill's square corners poke out of the track's
            // rounded ones at both ends.
            overflow: Overflow::clip(),
            ..default()
        },
        BackgroundColor(TRACK),
        children![(
            Node {
                width: percent(100),
                height: percent(100),
                ..default()
            },
            BackgroundColor(colour),
            fill_marker,
        )],
    )
}

/// The three colours a button wears.
///
/// Carried as a component rather than baked into each button's own system:
/// hover and press feedback is the difference between a button and a
/// rectangle, and it should not be something a new button can forget.
#[derive(Component, Clone, Copy)]
pub struct Tint {
    pub idle: Color,
    pub hovered: Color,
    pub pressed: Color,
}

impl Tint {
    /// Derives the hover and press shades from the resting one, so buttons
    /// that differ in hue still agree about how much brighter "hovered" is.
    pub fn new(idle: Color) -> Self {
        Self {
            idle,
            hovered: idle.lighter(0.06),
            pressed: idle.lighter(0.14),
        }
    }

    pub fn of(&self, interaction: Interaction) -> Color {
        match interaction {
            Interaction::None => self.idle,
            Interaction::Hovered => self.hovered,
            Interaction::Pressed => self.pressed,
        }
    }
}

/// A button with a label in it, tinted and sized like every other button.
///
/// `marker` lands on the button, `label_marker` on the text inside it — a
/// caller that rewrites the label later needs a handle on the text entity, and
/// reaching for it through `Children` every frame is worse than naming it.
pub fn button(
    text: impl Into<String>,
    idle: Color,
    marker: impl Bundle,
    label_marker: impl Bundle,
) -> impl Bundle {
    (
        Button,
        Node {
            padding: UiRect::axes(px(8), px(4)),
            border: UiRect::all(px(1)),
            border_radius: BorderRadius::all(px(RADIUS)),
            align_items: AlignItems::Center,
            ..default()
        },
        BackgroundColor(idle),
        BorderColor::all(PANEL_EDGE),
        Tint::new(idle),
        marker,
        children![(label(text, BODY, TEXT), label_marker)],
    )
}
