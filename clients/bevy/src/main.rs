//! The Bevy client, as a skeleton.
//!
//! This exists to prove one thing end to end: that a Bevy app builds for wasm,
//! deploys to GitHub Pages under `/bevy/`, and runs there beside the Flutter
//! client at `/flutter/`. It holds no combat rules and is not a port of
//! anything — the arena shape is drawn only so that "it rendered" is obvious at
//! a glance rather than a judgement call about a blank canvas.
//!
//! See `docs/architecture/` for where the real rules would live: a separate
//! crate with no Bevy dependency, driven by this one.

use bevy::prelude::*;

/// The mockup's formation: three columns, two rows, mirrored per side.
const ROWS: i32 = 2;
const COLUMNS: i32 = 3;

/// Arena geometry, in world units. The camera is fixed, so these are also
/// pixels at the default zoom.
const CELL: f32 = 64.0;
const GAP: f32 = 12.0;
const CENTRE_GAP: f32 = 96.0;

fn main() {
    App::new()
        .add_plugins(DefaultPlugins.set(WindowPlugin {
            primary_window: Some(Window {
                title: "Guild Overseer — Bevy client".into(),
                // The page owns the canvas so the loading text can be replaced
                // rather than sharing the document with a canvas Bevy appends.
                canvas: Some("#bevy-canvas".into()),
                fit_canvas_to_parent: true,
                // Let the browser keep its own shortcuts; a skeleton has no
                // claim on F5 or ctrl-W.
                prevent_default_event_handling: false,
                ..default()
            }),
            ..default()
        }))
        .insert_resource(ClearColor(Color::srgb(0.07, 0.08, 0.11)))
        .add_systems(Startup, setup)
        .add_systems(Update, breathe)
        .run();
}

/// Marks the squares that pulse, and how far through the cycle each one starts.
///
/// The pulse is the actual proof: a static image can be a cached first frame,
/// but movement means the schedule is running and the renderer is presenting.
#[derive(Component)]
struct Breathing {
    phase: f32,
}

fn setup(mut commands: Commands) {
    commands.spawn(Camera2d);

    for row in 0..ROWS {
        for column in 0..COLUMNS {
            spawn_slot(&mut commands, Side::Party, row, column);
            spawn_slot(&mut commands, Side::Dungeon, row, column);
        }
    }

    commands.spawn((
        Text::new("Guild Overseer — Bevy client skeleton"),
        TextFont {
            font_size: FontSize::Px(16.0),
            ..default()
        },
        TextColor(Color::srgb(0.75, 0.78, 0.85)),
        Node {
            position_type: PositionType::Absolute,
            top: Val::Px(16.0),
            left: Val::Px(16.0),
            ..default()
        },
    ));
}

#[derive(Clone, Copy)]
enum Side {
    Party,
    Dungeon,
}

impl Side {
    fn colour(self) -> Color {
        match self {
            Side::Party => Color::srgb(0.35, 0.62, 0.86),
            Side::Dungeon => Color::srgb(0.84, 0.36, 0.38),
        }
    }

    /// Column 0 is the front line for both sides, so the dungeon grid is the
    /// party grid mirrored rather than translated.
    fn x_of(self, column: i32) -> f32 {
        let offset = CENTRE_GAP / 2.0 + (CELL + GAP) * column as f32 + CELL / 2.0;
        match self {
            Side::Party => -offset,
            Side::Dungeon => offset,
        }
    }
}

fn spawn_slot(commands: &mut Commands, side: Side, row: i32, column: i32) {
    let y = (row as f32 - (ROWS - 1) as f32 / 2.0) * (CELL + GAP);
    commands.spawn((
        Sprite {
            color: side.colour(),
            custom_size: Some(Vec2::splat(CELL)),
            ..default()
        },
        Transform::from_xyz(side.x_of(column), -y, 0.0),
        Breathing {
            phase: (row * COLUMNS + column) as f32 * 0.4,
        },
    ));
}

/// A slow scale pulse, offset per slot so the grid ripples.
fn breathe(time: Res<Time>, mut squares: Query<(&Breathing, &mut Transform)>) {
    for (breathing, mut transform) in &mut squares {
        let t = time.elapsed_secs() * 1.5 + breathing.phase;
        transform.scale = Vec3::splat(0.94 + 0.06 * t.sin());
    }
}
