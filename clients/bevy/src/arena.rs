//! The formation grid, and the camera that frames it.
//!
//! The mockup's arena shape — three columns, two rows, mirrored per side — drawn
//! so that "it rendered" is obvious at a glance rather than a judgement call
//! about a blank canvas. There are no combat rules here; the squares pulse and
//! nothing else.

use bevy::camera::ScalingMode;
use bevy::prelude::*;

use crate::run;

/// The mockup's formation: three columns, two rows, mirrored per side.
const ROWS: i32 = 2;
const COLUMNS: i32 = 3;

/// Arena geometry, in world units.
const CELL: f32 = 64.0;
const GAP: f32 = 12.0;
const CENTRE_GAP: f32 = 96.0;

/// The box the camera must keep on screen, with room to breathe around it.
///
/// Derived rather than written down: change the grid above and the camera
/// still frames it. A window narrower than this ratio gets more vertical
/// background, a wider one more horizontal — nothing is ever cut off.
const ARENA_WIDTH: f32 =
    2.0 * (CENTRE_GAP / 2.0 + COLUMNS as f32 * CELL + (COLUMNS - 1) as f32 * GAP) + 2.0 * MARGIN;
const ARENA_HEIGHT: f32 = ROWS as f32 * CELL + (ROWS - 1) as f32 * GAP + 2.0 * MARGIN;
const MARGIN: f32 = 24.0;

/// The HUD sits over the arena, so the arena has to leave it somewhere to sit:
/// the camera frames a taller box than the grid needs and the grid keeps the
/// middle of it.
const HUD_HEADROOM: f32 = 150.0;

pub struct ArenaPlugin;

impl Plugin for ArenaPlugin {
    fn build(&self, app: &mut App) {
        app.add_systems(Startup, setup)
            // Paused means paused: the pulse is the one thing on screen that
            // proves the schedule is running, so freezing it is how a player
            // sees that the pause button did anything at all.
            .add_systems(Update, breathe.run_if(run::running));
    }
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
    // Fit, rather than one world unit per pixel: at the default projection a
    // phone-width viewport shows ~400 units of a 576-unit arena and clips the
    // outer columns off both sides.
    commands.spawn((
        Camera2d,
        Projection::from(OrthographicProjection {
            scaling_mode: ScalingMode::AutoMin {
                min_width: ARENA_WIDTH,
                min_height: ARENA_HEIGHT + HUD_HEADROOM,
            },
            ..OrthographicProjection::default_2d()
        }),
    ));

    for row in 0..ROWS {
        for column in 0..COLUMNS {
            spawn_slot(&mut commands, Side::Party, row, column);
            spawn_slot(&mut commands, Side::Dungeon, row, column);
        }
    }
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
