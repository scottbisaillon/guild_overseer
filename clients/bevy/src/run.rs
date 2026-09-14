//! A stand-in for the state an active run would publish.
//!
//! The HUD has to read *something*, and this crate deliberately holds no combat
//! rules — those belong in the separate crate `docs/architecture/` describes.
//! So this is a puppet: it drains health, spins cooldowns, walks the party
//! through rooms and writes log lines on a timer, purely so that every widget
//! in [`crate::hud`] can be seen doing its job in a running app.
//!
//! Nothing here is a rule and nothing here should grow into one. The shape is
//! the point: when the real simulation arrives it publishes a resource like
//! this one and the HUD does not change.

use std::collections::VecDeque;

use bevy::prelude::*;

/// Rooms in a run. The last one is the boss room.
pub const ROOM_COUNT: usize = 5;

/// The widest rotation the HUD reserves slots for. A member with fewer skills
/// than this leaves the remaining slots collapsed rather than empty.
pub const MAX_SKILLS: usize = 4;

/// How long the puppet spends in a room before moving to the next.
const ROOM_DURATION: f32 = 16.0;

/// How long after entering the boss room the enrage timer expires.
const ENRAGE_AFTER: f32 = 45.0;

/// And how long after that the puppet starts the run over.
const RESTART_AFTER: f32 = 6.0;

/// Lines kept in the log. The panel shows the last few; the rest are scrolled
/// off, which is what a bounded queue is for.
const LOG_CAPACITY: usize = 24;

/// A member never quite dies here. Death is a rule, and rules live elsewhere.
const HEALTH_FLOOR: f32 = 0.08;

pub struct RunPlugin;

/// The set [`tick`] runs in, so that everything reading [`RunState`] can order
/// itself after the frame's changes rather than a frame behind them.
#[derive(SystemSet, Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct Tick;

impl Plugin for RunPlugin {
    fn build(&self, app: &mut App) {
        app.init_resource::<RunState>()
            .add_systems(Update, tick.in_set(Tick).run_if(running));
    }
}

/// The gate the pause button turns, as a run condition.
pub fn running(state: Res<RunState>) -> bool {
    !state.paused
}

/// What the HUD draws.
#[derive(Resource)]
pub struct RunState {
    pub members: Vec<Member>,
    /// Which member's rotation and target priority the HUD is showing.
    pub selected: usize,
    pub room: usize,
    pub elapsed: f32,
    pub paused: bool,
    pub log: VecDeque<LogLine>,
    /// Bumped on every push. The log view needs to tell "nothing happened"
    /// from "one line in, one line out", and a bounded queue's length cannot.
    pub log_seq: u64,
    room_elapsed: f32,
    damage_in: f32,
    heal_in: f32,
    rng: Rng,
}

impl Default for RunState {
    fn default() -> Self {
        let members = vec![
            Member::new(
                "Brenna",
                Role::Tank,
                980,
                vec![
                    Skill::new("Taunt", 6.0),
                    Skill::new("Slam", 9.0),
                    Skill::new("Bulwark", 21.0),
                ],
            ),
            Member::new(
                "Osric",
                Role::Healer,
                620,
                vec![
                    Skill::new("Mend", 4.0),
                    Skill::new("Renew", 12.0),
                    Skill::new("Ward", 25.0),
                ],
            ),
            Member::new(
                "Marl",
                Role::MeleeDps,
                740,
                vec![
                    Skill::new("Cleave", 5.0),
                    Skill::new("Rend", 8.0),
                    Skill::new("Rush", 14.0),
                    Skill::new("Finish", 19.0),
                ],
            ),
            Member::new(
                "Kite",
                Role::RangedDps,
                610,
                vec![
                    Skill::new("Aim", 3.0),
                    Skill::new("Volley", 11.0),
                    Skill::new("Mark", 17.0),
                ],
            ),
        ];

        let mut state = Self {
            members,
            selected: 0,
            room: 0,
            elapsed: 0.0,
            paused: false,
            log: VecDeque::with_capacity(LOG_CAPACITY),
            log_seq: 0,
            room_elapsed: 0.0,
            damage_in: 1.0,
            heal_in: 2.2,
            rng: Rng::seeded(0x5EED_1234),
        };

        // Stagger the rotations so the cooldown row ripples instead of firing
        // in lockstep — lockstep looks like one animation, not four.
        for (index, member) in state.members.iter_mut().enumerate() {
            for (slot, skill) in member.skills.iter_mut().enumerate() {
                let through = (0.2 * index as f32 + 0.17 * slot as f32) % 1.0;
                skill.remaining = skill.cooldown * through;
            }
        }

        state.push(LogKind::Notice, "The party enters room 1.".to_string());
        state
    }
}

impl RunState {
    pub fn selected(&self) -> &Member {
        &self.members[self.selected]
    }

    pub fn boss_room(&self) -> bool {
        self.room + 1 == ROOM_COUNT
    }

    /// Seconds until the boss enrages, or `None` outside the boss room. The
    /// clock in the top bar is the same widget either way; only what it counts
    /// changes.
    pub fn enrage_in(&self) -> Option<f32> {
        self.boss_room()
            .then(|| (ENRAGE_AFTER - self.room_elapsed).max(0.0))
    }

    pub fn push(&mut self, kind: LogKind, text: String) {
        if self.log.len() == LOG_CAPACITY {
            self.log.pop_front();
        }
        self.log.push_back(LogLine {
            at: self.elapsed,
            kind,
            text,
        });
        self.log_seq += 1;
    }
}

/// One party member, as far as the HUD is concerned.
pub struct Member {
    pub name: &'static str,
    pub role: Role,
    /// A fraction of full health, because every widget that shows it wants a
    /// fraction: the bar's width, the percentage label, the colour threshold.
    pub health: f32,
    pub max_health: u32,
    /// Creeps up over a run and never recovers inside one. See
    /// `docs/systems/members.md`.
    pub fatigue: f32,
    pub status: Status,
    pub priority: TargetPriority,
    pub skills: Vec<Skill>,
    /// How long the current status has left before it lapses back to seeking.
    /// A status that lasted the one frame that caused it would be a label
    /// nobody could read.
    status_for: f32,
}

impl Member {
    fn new(name: &'static str, role: Role, max_health: u32, skills: Vec<Skill>) -> Self {
        Self {
            name,
            role,
            health: 1.0,
            max_health,
            fatigue: 0.0,
            status: Status::Seeking,
            priority: role.default_priority(),
            skills,
            status_for: 0.0,
        }
    }

    /// Being stunned outranks anything else the member might be doing, which
    /// is the one piece of precedence this puppet needs.
    fn set_status(&mut self, status: Status, seconds: f32) {
        if self.status == Status::Stunned && status != Status::Stunned {
            return;
        }
        self.status = status;
        self.status_for = seconds;
    }
}

#[derive(Clone, Copy, PartialEq, Eq)]
pub enum Role {
    Tank,
    Healer,
    MeleeDps,
    RangedDps,
}

impl Role {
    pub fn label(self) -> &'static str {
        match self {
            Role::Tank => "tank",
            Role::Healer => "healer",
            Role::MeleeDps => "melee",
            Role::RangedDps => "ranged",
        }
    }

    fn default_priority(self) -> TargetPriority {
        match self {
            Role::Tank => TargetPriority::Threat,
            Role::Healer => TargetPriority::Nearest,
            Role::MeleeDps => TargetPriority::Nearest,
            Role::RangedDps => TargetPriority::Weakest,
        }
    }
}

/// What a member is doing, as the HUD would report it.
#[derive(Clone, Copy, PartialEq, Eq)]
pub enum Status {
    Seeking,
    Firing,
    Stunned,
}

impl Status {
    pub fn label(self) -> &'static str {
        match self {
            Status::Seeking => "seeking",
            Status::Firing => "firing",
            Status::Stunned => "stunned",
        }
    }
}

/// The target priorities from `docs/systems/combat.md`, as a cycle the HUD can
/// step through with one button.
#[derive(Clone, Copy, PartialEq, Eq)]
pub enum TargetPriority {
    Nearest,
    Weakest,
    Threat,
    Strongest,
    Manual,
}

impl TargetPriority {
    pub fn label(self) -> &'static str {
        match self {
            TargetPriority::Nearest => "nearest",
            TargetPriority::Weakest => "weakest",
            TargetPriority::Threat => "threat",
            TargetPriority::Strongest => "strongest",
            TargetPriority::Manual => "manual",
        }
    }

    pub fn next(self) -> Self {
        match self {
            TargetPriority::Nearest => TargetPriority::Weakest,
            TargetPriority::Weakest => TargetPriority::Threat,
            TargetPriority::Threat => TargetPriority::Strongest,
            TargetPriority::Strongest => TargetPriority::Manual,
            TargetPriority::Manual => TargetPriority::Nearest,
        }
    }
}

pub struct Skill {
    pub name: &'static str,
    pub cooldown: f32,
    /// Counts down to zero and then keeps going, negative, while the skill
    /// sits ready. Without that pause a skill would fire on the frame it came
    /// up and the HUD would never once show a ready slot.
    pub remaining: f32,
    /// How long ready is allowed to last before the puppet fires again.
    hold: f32,
}

impl Skill {
    fn new(name: &'static str, cooldown: f32) -> Self {
        Self {
            name,
            cooldown,
            remaining: 0.0,
            hold: 0.5 + cooldown * 0.06,
        }
    }

    /// How much of the cooldown is left, as a fraction — the height of the
    /// sweep drawn over the slot.
    pub fn cooling(&self) -> f32 {
        (self.remaining / self.cooldown).clamp(0.0, 1.0)
    }
}

pub struct LogLine {
    pub at: f32,
    pub kind: LogKind,
    pub text: String,
}

/// What a log line is about. The log colours by kind rather than by author, so
/// a glance at the panel reads as a shape before it reads as words.
#[derive(Clone, Copy, PartialEq, Eq)]
pub enum LogKind {
    Damage,
    Heal,
    Skill,
    Loot,
    Notice,
}

/// Sends the party back to the first room with their wounds closed. The run
/// clock is left alone: it counts the session, and a log full of timestamps
/// that jump backwards helps nobody.
fn restart(state: &mut RunState) {
    state.room = 0;
    state.room_elapsed = 0.0;
    for member in &mut state.members {
        member.health = 1.0;
        member.fatigue = 0.0;
        member.status = Status::Seeking;
        member.status_for = 0.0;
    }
    state.push(LogKind::Notice, "The party regroups at room 1.".into());
}

/// Walks the puppet forward one frame.
fn tick(time: Res<Time>, mut state: ResMut<RunState>) {
    let delta = time.delta_secs();
    state.elapsed += delta;
    state.room_elapsed += delta;

    advance_room(&mut state);
    fire_rotations(&mut state, delta);
    take_damage(&mut state, delta);
    heal_up(&mut state, delta);

    for member in &mut state.members {
        member.fatigue = (member.fatigue + delta * 0.004).min(1.0);

        member.status_for -= delta;
        if member.status_for <= 0.0 && member.status != Status::Seeking {
            member.status = Status::Seeking;
        }
    }
}

fn advance_room(state: &mut RunState) {
    if state.boss_room() {
        // What happens when an enrage timer runs out is a rule, and rules live
        // elsewhere. The puppet waits a beat and starts the run over, so that
        // everything the room strip can show keeps being shown.
        if state.room_elapsed > ENRAGE_AFTER + RESTART_AFTER {
            restart(state);
        }
        return;
    }

    if state.room_elapsed < ROOM_DURATION {
        return;
    }

    state.room += 1;
    state.room_elapsed = 0.0;

    let coins = 12 + state.rng.below(40);
    state.push(LogKind::Loot, format!("Room cleared: {coins} silver."));
    if state.boss_room() {
        state.push(LogKind::Notice, "The boss room. Enrage is running.".into());
    } else {
        let room = state.room + 1;
        state.push(LogKind::Notice, format!("The party enters room {room}."));
    }
}

/// Runs every member's cooldowns down, lets them sit ready for a moment, and
/// then fires and restarts them — logging each fire on the way past.
fn fire_rotations(state: &mut RunState, delta: f32) {
    let mut fired = Vec::new();

    for member in &mut state.members {
        let mut firing = false;
        for skill in &mut member.skills {
            skill.remaining -= delta;
            if skill.remaining <= -skill.hold {
                skill.remaining = skill.cooldown;
                fired.push((member.name, skill.name));
                firing = true;
            }
        }
        if firing {
            member.set_status(Status::Firing, 0.9);
        }
    }

    for (member, skill) in fired {
        state.push(LogKind::Skill, format!("{member} casts {skill}."));
    }
}

fn take_damage(state: &mut RunState, delta: f32) {
    state.damage_in -= delta;
    if state.damage_in > 0.0 {
        return;
    }
    state.damage_in = 0.7 + state.rng.fraction() * 0.9;

    let target = state.rng.below(state.members.len());
    let fraction = 0.03 + state.rng.fraction() * 0.07;
    let stun = state.rng.fraction() < 0.12;

    let member = &mut state.members[target];
    let amount = (fraction * member.max_health as f32).round() as u32;
    member.health = (member.health - fraction).max(HEALTH_FLOOR);
    if stun {
        member.set_status(Status::Stunned, 1.8);
    }

    let name = member.name;
    state.push(LogKind::Damage, format!("{name} takes {amount}."));
}

fn heal_up(state: &mut RunState, delta: f32) {
    state.heal_in -= delta;
    if state.heal_in > 0.0 {
        return;
    }
    state.heal_in = 1.3 + state.rng.fraction() * 1.1;

    // Whoever is worst off, which is what a healer's rotation amounts to at
    // this level of detail.
    let Some(target) = (0..state.members.len())
        .min_by(|&a, &b| state.members[a].health.total_cmp(&state.members[b].health))
    else {
        return;
    };

    let healer = state
        .members
        .iter()
        .find(|member| member.role == Role::Healer)
        .map_or("The healer", |member| member.name);

    let fraction = 0.05 + state.rng.fraction() * 0.08;
    let member = &mut state.members[target];
    let amount = (fraction * member.max_health as f32).round() as u32;
    member.health = (member.health + fraction).min(1.0);
    if member.status == Status::Stunned {
        member.status = Status::Seeking;
        member.status_for = 0.0;
    }

    let line = if member.name == healer {
        format!("{healer} recovers {amount}.")
    } else {
        let name = member.name;
        format!("{healer} mends {name} for {amount}.")
    };
    state.push(LogKind::Heal, line);
}

/// xorshift32: deterministic, seedable, and cheaper than a dependency for
/// numbers nobody is betting on.
struct Rng(u32);

impl Rng {
    fn seeded(seed: u32) -> Self {
        Self(seed.max(1))
    }

    fn next_u32(&mut self) -> u32 {
        let mut x = self.0;
        x ^= x << 13;
        x ^= x >> 17;
        x ^= x << 5;
        self.0 = x;
        x
    }

    /// A number in `0.0..1.0`.
    fn fraction(&mut self) -> f32 {
        self.next_u32() as f32 / u32::MAX as f32
    }

    fn below(&mut self, bound: usize) -> usize {
        self.next_u32() as usize % bound.max(1)
    }
}
