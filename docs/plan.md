# Vertical Slice — Task Plan

**Engine:** Bevy 0.15 · Rust · ECS  
**UI:** `bevy_egui` — retro minimalist style  
**Tilemap:** `bevy_ecs_tilemap`  
**Persistence:** `bevy_reflect` + RON serialisation  
**Data:** RON asset files loaded via `AssetServer`

Implementation details live in the relevant system or UI file. This plan tracks task completion and phase milestones only.

---

## Phase 00 — Early Game Loop

> [!milestone] Adventurer phase playable end-to-end: character creation → shared tavern → dungeon run → reputation → guild founding.

- [ ] 0.1 Build character creation screen — class selector, starting trait display, skill tree entry, character naming #ui
	- Five classes. Class choice permanent. Show strategic implication of each. See [[ui/skill-editor]].
- [ ] 0.2 Implement player character as permanent entity — `PlayerCharacter` marker component alongside all standard member components #logic
	- See [[systems/members#Bevy Notes]]. Zero-sized marker — no special logic needed beyond `With<PlayerCharacter>` queries where distinction matters.
- [ ] 0.3 Implement shared tavern pool — abstract pool gated by reputation tier, fixed 4 recruits, refresh timer #logic
	- See [[systems/reputation]]. Same recruitment system as the guild Tavern, different tier input.
- [ ] 0.4 Build shared tavern UI — recruit list with trait badges, reputation tier indicator, hire button, refresh countdown #ui
	- See [[ui/tavern]].
- [ ] 0.5 Implement Reputation system — five-factor formula reading from `RunCompleted` events, milestone threshold checks #logic
	- See [[systems/reputation#Bevy Notes]]. Pure calculation function — unit-testable in isolation.
- [ ] 0.6 Build Reputation display — progress bar toward next milestone, last run contribution breakdown #ui
- [ ] 0.7 Implement active vs idle routing — dispatch system checks `PlayerCharacter` presence in party, sets `AppState` accordingly #logic
	- See [[early-game#Active vs Idle — The Defining Mechanic]].
- [ ] 0.8 Implement player character death — run ends immediately, partial loot and reputation from completed rooms awarded #logic
	- Stub the run-continuation path for future implementation. See [[early-game#Player Character Death]].
- [ ] 0.9 Implement guild founding — reputation threshold check, Gold cost, naming screen, `AppState` transition to hub, first event log entry #logic #ui
	- See [[early-game#Founding the Guild]].
- [ ] 0.10 End-to-end early game test — character creation → recruit → run → reputation earned → found guild → hub unlocks #test

---

## Phase 01 — Project Foundation

> [!milestone] Bevy app boots. ECS world initialised. Resources and Components defined. Save/load round-trips. egui renders with retro style applied.

- [ ] 1.1 Create Rust project — Cargo workspace, core dependencies: `bevy`, `bevy_egui`, `bevy_ecs_tilemap`, `serde`, `ron` #arch
	- Pin Bevy to a specific minor version. Plugin dependencies can break on upgrades — control when you update.
- [ ] 1.2 Set up module structure — `components/`, `systems/`, `resources/`, `plugins/`, `ui/`, `data/` #arch
	- Each domain (combat, recruitment, loot) gets its own `Plugin` struct registered in `main.rs`. Keeps `App` setup lean and modular.
- [ ] 1.3 Define core `Component` structs — `Health`, `Morale`, `Fatigue`, `Loyalty`, `Velocity`, `TraitSet`, `SkillRotation`, `CurrentTarget`, `ThreatTable`, `GearSlots` #arch
	- See [[systems/members#Bevy Notes]]. All derive `Component`, `Reflect`, `Default`. `Reflect` required for save serialisation.
- [ ] 1.4 Define core `Resource` structs — `Currencies`, `GuildHall`, `ActiveRun`, `GuildStash`, `TavernPool`, `EventLog` #arch
	- See [[systems/economy#Bevy Notes]]. All derive `Reflect`. Resources are global singletons inserted via `app.insert_resource(...)`.
- [ ] 1.5 Define game event types — `QTEFailed`, `QTESolved`, `TraitTriggered`, `SkillFired`, `LootDropped`, `MemberDied`, `ThreatChanged`, `RunCompleted`, `DramaEventQueued` — derive `Event` #arch
	- Bevy's `EventWriter<T>` / `EventReader<T>` is the event bus. No separate pub/sub class needed.
- [ ] 1.6 Implement `SavePlugin` — serialise all `Reflect`-registered components and resources to RON on exit and manual save #arch #save
	- Include a `schema_version` field in the root save struct from day one.
- [ ] 1.7 Implement save load on startup — validate schema version, spawn entities from saved component data #arch #save
- [ ] 1.8 Configure egui retro style — monospace pixel font, flat colours, zero corner rounding — applied once in a `Startup` system #ui
- [ ] 1.9 Smoke test: spawn entity with components, write and read a game event, verify save round-trips #test

---

## Phase 02 — Static Data

> [!milestone] All game data loaded from RON assets, parsed into typed Rust structs, cached in Resources. Compiler enforces completeness at parse time.

- [ ] 2.1 Author `traits.ron` and `TraitDefinition` struct — all 12 launch traits #data
	- See [[systems/traits#Trait Schema]].
- [ ] 2.2 Author `classes.ron` and `ClassDefinition` struct — 4 classes, base stats, role, skill ID lists #data
- [ ] 2.3 Author `skills.ron` and `SkillDefinition` struct — type, branch, cooldown, finisher sequences as ordered `Vec<SkillId>` #data
	- See [[systems/skills]].
- [ ] 2.4 Author `dungeons.ron` and `DungeonDefinition` struct — 2 dungeons, room pools, boss phases, QTE patterns per phase #data
	- See [[systems/dungeon#Data Definition]].
- [ ] 2.5 Author `items.ron` and `ItemDefinition` struct — Common through Epic, stat ranges, slot assignments #data
- [ ] 2.6 Author `drama_events.ron` — 8–10 events with resolution options and morale/loyalty costs #data
- [ ] 2.7 Author `upgrades.ron` and `game_config.ron` — facility tiers, costs, reputation thresholds #data
- [ ] 2.8 Implement `DataPlugin` — load all asset files in `Startup` via `AssetServer`, parse via serde, insert as `Resource` structs #data #arch

---

## Phase 03 — Core Game Logic

> [!milestone] All game logic implemented as pure Rust functions. `cargo test` passes. The game can simulate itself headlessly.

- [ ] 3.1 Implement member spawning — system that bundles all component structs onto a new entity from class and trait definition inputs #logic
	- See [[systems/members#Bevy Notes]].
- [ ] 3.2 Implement `trait_evaluation_system` — reads `GameEvent`s, evaluates trait trigger conditions from `Res<TraitData>`, writes `TraitTriggered` events #logic
	- See [[systems/traits#Bevy Notes]].
- [ ] 3.3 Implement `trait_response_system` — reads `TraitTriggered` events, mutates member components, writes `DramaEventQueued` events #logic
- [ ] 3.4 Implement `rotation_evaluator` — pure function returning `RqsResult` from rotation + dungeon definition inputs #logic
	- See [[systems/rotation#Bevy Notes]]. No ECS dependencies. Fully unit-testable.
- [ ] 3.5 Implement `progression_system` — post-run XP gain, level-up, morale decay, fatigue accumulation per member #logic
- [ ] 3.6 Implement `recruitment_system` — reputation-weighted trait rarity rolls, rare combo detection, pool generation #logic
- [ ] 3.7 Implement `loot_generation_system` — reads room result events, rolls drops from dungeon tables, writes to `Res<GuildStash>` #logic
	- See [[systems/loot#Bevy Notes]].
- [ ] 3.8 Unit-test all logic — RQS scoring, trait evaluation cascade, loot rolls, level-up thresholds, aggro break, reputation calculation #test

---

## Phase 04 — Guild Hall Hub

- [ ] 4.1 Build navigation — `egui::TopBottomPanel::top` with tab buttons and currency display #ui
	- See [[ui/guild-hall]].
- [ ] 4.2 Build guild hall tile map — `bevy_ecs_tilemap` floor and facility tiles, member sprite wandering entities #ui
- [ ] 4.3 Build member roster panel — `egui::SidePanel::left`, morale and fatigue `ProgressBar` per member #ui
- [ ] 4.4 Build events feed panel — `egui::SidePanel::right`, scrolling `EventLog` resource entries #ui
- [ ] 4.5 Build status bar — `egui::TopBottomPanel::bottom`, rep bar, active run count, loot pending #ui
- [ ] 4.6 Build member detail — `egui::Window` on roster click: full stats, traits, gear slots, link to skill editor #ui
- [ ] 4.7 Implement facility notification badges — sprite overlay entities driven by a system watching `Res<GuildHall>` and `Res<GuildStash>` #logic #ui

---

## Phase 05 — Recruitment, Skills & Party

- [ ] 5.1 Build Tavern screen — recruit list with trait badges, rarity indicators, hire button, refresh timer #ui
	- See [[ui/tavern]].
- [ ] 5.2 Implement Tavern refresh timer — `Timer` in `Res<TavernPool>` decremented by `Res<Time>`, pool regen on expiry #logic #save
- [ ] 5.3 Build Skill Tree node graph — `egui::Painter` for edges and nodes, invest/refund on click #ui
	- See [[ui/skill-editor]].
- [ ] 5.4 Build Rotation Builder — ordered slot list with skill selection per slot, always-active passive section below #ui
- [ ] 5.5 Wire live RQS preview — `rotation_evaluator()` called each frame in egui system, factor breakdown displayed, colour-coded bar #ui #logic
	- See [[systems/rotation#Bevy Notes]].
- [ ] 5.6 Build Party Composer — dungeon selector, party slot list, composition bars, dispatch button #ui
	- See [[ui/party-composer]].
- [ ] 5.7 Implement live trait conflict warnings — `evaluate_conflicts()` called inline in composer UI each frame, conflicting slots highlighted red #ui #logic
- [ ] 5.8 Implement dispatch — validates requirements, creates `Res<ActiveRun>`, sets `AppState`, triggers save #logic #save

---

## Phase 06 — Idle Dungeon Run

> [!milestone] Full idle loop tested headlessly. Deterministic resolution. Offline progression. Trait events and drama fire mid-run.

- [ ] 6.1 Implement `dungeon_tick_system` — advances `ActiveRun` room index on `Timer` expiry, resolves each room via stat formulas #logic
	- See [[systems/dungeon#Bevy Notes]]. Gated by `if !active_run.is_active`.
- [ ] 6.2 Implement offline progression — `Startup` system reads `last_saved_at`, fast-forwards `ActiveRun` up to 8-hour cap #logic #save
- [ ] 6.3 Integrate `TraitEngine` into idle tick — tick system writes `GameEvent`s, trait evaluation system reads them same frame #logic
- [ ] 6.4 Integrate RQS into idle tick — `rotation_evaluator()` called per member, result applied as damage multiplier on combat rooms #logic
- [ ] 6.5 Build idle run screen — room progress bar, scrolling event log, ETA countdown from run timer #ui
- [ ] 6.6 Build drama event dialog — `egui::Window` with event text and resolution buttons, writes `DramaResolved` event on confirmation #ui #logic
- [ ] 6.7 Headless end-to-end test — `App::update()` loop, advance timers, assert `GuildStash` and member component values after run #test

---

## Phase 07 — Active Dungeon Run

> [!milestone] ECS combat alive. Entities pathfind and engage. QTEs fire and resolve. Trait cascade proven end-to-end.

- [ ] 7.1 Build dungeon room — `bevy_ecs_tilemap` tile grid, spawn member and enemy entities with `Transform` and `Sprite` #ui
	- See [[ui/active-run]].
- [ ] 7.2 Implement 8-direction sprite — `SpriteAnimationComponent` with Kenney top-down assets, `flip_x` tied to horizontal velocity sign each frame #ui
- [ ] 7.3 Implement steering behaviours — seek, arrive, separation computed as a summed velocity vector per frame in `steering_system` #logic
	- See [[systems/combat#Bevy Notes]]. Manual vector math — no physics engine needed at this entity count.
- [ ] 7.4 Implement target priority system — `targeting_system` evaluates priority function against living enemies, caches result in `CurrentTarget` until stale #logic
	- See [[systems/combat#Target Priority]].
- [ ] 7.5 Implement trait targeting bias — pure function returning a `TargetBias` enum called inside `targeting_system`, applied as a score weight before target selection #logic
	- See [[systems/traits#Targeting Overrides]].
- [ ] 7.6 Implement enemy AI — `ThreatTable` component per enemy, updated by `threat_system` reading `SkillFired` events, aggro break on threshold #logic
	- See [[systems/combat#Enemy AI & Threat]].
- [ ] 7.7 Implement range detection and rotation firing — `InRange` marker added/removed by `range_detection_system`, rotation firing gated on `With<InRange>` #logic
	- See [[systems/rotation#Bevy Notes]] and [[systems/combat#Attack Range & Rotation Firing]].
- [ ] 7.8 Implement QTE system — QTE entity with position and countdown timer, egui `Area` overlay at `Camera::world_to_viewport()` projected position #logic #ui
	- See [[systems/qte#Bevy Notes]].
- [ ] 7.9 Implement QTE miss consequences — `qte_consequence_system` reads `QTEFailed`, applies damage/debuffs/fatigue to components, writes `GameEvent`s for trait cascade #logic
- [ ] 7.10 Build active run HUD — HP bars, target priority dropdowns, skill cooldowns, enrage timer, combat log, retreat button #ui
	- See [[ui/active-run#Bevy Notes]].
- [ ] 7.11 Implement boss phases — `boss_phase_system` reads boss entity `Health`, transitions phase component at HP thresholds, loads new QTE patterns, spawns Phase 3 adds #logic
	- See [[systems/qte#Boss Phases]].
- [ ] 7.12 Headless combat test — spawn party and enemies, tick `App`, fire `QTEFailed`, assert member component values after trait cascade #test
- [ ] 7.13 Play-test — pathfinding feel, QTE overlay accuracy, aggro readability, trait reactions firing as expected #test

---

## Phase 08 — Loot, Polish & Sign-off

> [!milestone] Full vertical slice complete: recruit → skills → party → idle run → active run → loot → repeat.

- [ ] 8.1 Build post-run summary — `egui::Window` with run result, XP, loot count, drama events, stat diffs from `Res<RunSummary>` #ui
- [ ] 8.2 Build Loot Distribution screen — item list, member assign selector, disenchant button #ui
	- See [[ui/loot-distribution]].
- [ ] 8.3 Implement Goblin claim dialog — `egui::Window` with allow/override, writes `GoblinClaimResolved` event #ui #logic
	- See [[systems/loot#Bevy Notes]].
- [ ] 8.4 Implement gear equipping — `LootAssigned` event system updates `GearSlots` component, adjusts morale and loyalty #logic
- [ ] 8.5 Implement post-run member updates — fatigue recovery, morale/loyalty drift, XP → level-up with skill point grant #logic
- [ ] 8.6 Implement Guild Reputation update and dungeon unlock check after run completion #logic
	- See [[systems/reputation#Bevy Notes]].
- [ ] 8.7 Implement Flawless Clear — `qte_miss_tracker` counts `QTEFailed` events during run, `FlawlessClear` event written on zero-miss completion #logic
	- See [[systems/qte#Flawless Clear]].
- [ ] 8.8 Polish pass — consistent egui style throughout, button feedback, window transitions #ui
- [ ] 8.9 Full loop play-through — recruit → skills → party → idle run → active run → loot → repeat. No dead ends. #test
- [ ] 8.10 Save/load stress test — write save mid-active-run, reload, verify entity components and resource state restore correctly via RON #test #save

---

## Tags

`#arch` — Architecture / project structure  
`#data` — RON schema / static data  
`#logic` — ECS systems and game logic  
`#ui` — egui / bevy_ecs_tilemap rendering  
`#save` — RON serialisation / persistence  
`#test` — `cargo test` / headless `App::update()` / play-test
