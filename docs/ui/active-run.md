# UI — Active Run Screen

The active dungeon view. Bevy renders the world (tile room, sprite entities, QTE overlays). `bevy_egui` renders the HUD above.

**Depends on:** [[../systems/combat]], [[../systems/qte]], [[../systems/rotation]], [[../systems/members]]

---

## Components

- **Tile room** — `bevy_ecs_tilemap` floor and walls. Room size from `dungeons.ron`.
- **Entity sprites** — `SpriteAnimationComponent` per member and enemy. Flip X on velocity direction.
- **Room progress bar** — top strip showing room sequence with current room highlighted. Boss room marked distinctly.
- **Enrage timer** — visible from the moment the boss room begins. Red countdown.
- **HP bars per member** — current HP percentage, fatigue level, and status text (seeking, firing, stunned, etc.).
- **Member tab switcher** — select which member's skill cooldowns to display.
- **Skill cooldown display** — active skill slots for the selected member with cooldown overlays.
- **Target priority selector** — per-member dropdown: Nearest, Weakest, Threat, Strongest, Manual.
- **Combat log** — scrolling panel of damage numbers, skill fires, loot drops, trait events.
- **QTE overlay** — safe zone circle and single-target badge rendered at world-to-screen projected positions. See [[../systems/qte]].
- **Retreat button** — ends the run, preserving partial loot and reputation from completed rooms.

---

## Implementation Notes

### Bevy

The HUD is entirely `bevy_egui` panels. The game world is standard Bevy rendering beneath. Both coexist naturally via `bevy_egui`'s render integration.

QTE overlays are positioned using `Camera::world_to_viewport()` to project the QTE entity's world-space position to screen space for the `egui::Area`. This keeps the overlay correctly positioned relative to game entities regardless of camera movement.

HP bars and cooldowns read directly from ECS components each frame — immediate-mode egui means no sync layer is required between game state and UI state.

### Flutter + Flame
A Flutter screen with a `Stack`: `GameWidget` (the Flame `DungeonGame`) fills the screen, Flutter `Positioned` widgets sit above for the HUD. This is the core Flutter + Flame integration pattern.

HP bars, skill cooldowns, target priority dropdowns, and the combat log are all Flutter widgets watching `combatStateProvider` — a provider derived from the `StreamController<GameEvent>` stream that `DungeonGame` emits to. No canvas-drawn HUD.

QTE prompts are `Positioned` `GestureDetector` widgets. Their screen position is projected from world-space using `camera.worldToScreen()` in a system that writes to `combatStateProvider`. Tapping calls `dungeonGame.resolveQTE()` via a passed callback. This gives native platform touch handling with zero latency.

The enrage timer is a `StreamProvider` countdown from `ActiveRun.enrageAt`.
