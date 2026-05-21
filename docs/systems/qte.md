# Quick-Time Events (QTEs)

QTEs are the primary active input mechanic during dungeon runs. When an enemy telegraphs a dangerous ability the player must respond within a time window. First-iteration QTEs are intentionally simple — complexity scales with dungeon tier.

**Depends on:** [[combat]], [[traits]], [[dungeon]], [[members]]

---

## QTE Types

### Global QTE

A visible safe zone appears in the room. The player taps or clicks it to issue a simultaneous move command to all party members. Members pathfind to the safe zone, interrupting their current seek behaviour temporarily.

- Safe zone is always unambiguous — clear green circle contrasting the red danger zone.
- Once the hazard resolves, members automatically resume their prior targeting.
- Certain [[traits|traits]] may resist the move command.

### Single-Target QTE

A prompt appears above a specific party member. The player taps the prompt to have that member fire their Reactive skill. If no Reactive skill is available, the member performs a basic dodge.

- Missing it applies consequences only to that member.
- The Veteran trait reveals prompts earlier in previously-cleared dungeons.

---

## Telegraph Types

| Telegraph | Timing Window | Miss Consequence |
|---|---|---|
| Ground AoE | 1.5–2.5s | All members in zone take heavy damage |
| Cone Attack | 1.0–2.0s | Front-line members take moderate-heavy damage |
| Targeted Strike | 0.8–1.5s | Targeted member takes concentrated hit |
| Knockback Wave | 1.5s | Members pushed into hazard zones; collision damage near walls |
| Column Laser | 2.0s | Members in line take very high damage + burn debuff |
| Multi-Target Barrage | 1.2s | Multiple members targeted simultaneously |

Telegraph windows compress with dungeon difficulty. Legendary tier uses 0.6–0.8s windows with layered simultaneous telegraphs.

---

## Miss Consequences

| Consequence | Description |
|---|---|
| Direct Damage | Full attack value, modified by defence stats and active Auras |
| Debuff | Burn (DoT), Stun (skips next rotation cycle), Slow, Knockdown (2s unavailable) |
| Fatigue Spike | +10–20 Fatigue on top of normal accumulation |
| Morale Damage | Scales with how avoidable the hit was |
| Party Morale Contagion | Witnessing repeated avoidable hits reduces other members' morale |

---

## Trait Reactions

| Trait | Trigger | Reaction |
|---|---|---|
| Tryhard | Self hit by avoidable QTE | Morale −12. Two consecutive misses → Frustration mode: +15% damage, ignores next global QTE. |
| Tryhard | Zero misses in a room | Morale +10. Brief party damage buff for next room. |
| Drama Queen | Nearby member fails a QTE | Blame Event on the failing member (−5 morale). If self fails → Rage mode: +20% damage, ignores move commands 15s. |
| Glass Cannon | Hit by any QTE | Takes 60% additional damage. Single missed AoE frequently fatal. |
| Pacifist Healer | Any member below 20% HP from QTE hit | Breaks rotation to emergency-heal immediately. |
| Tank Mentality | Targeted Strike aimed at adjacent ally | Tank physically intercepts the hit. Player does not need to react. |
| AFK Prone | Global QTE during AFK window | Does not move to safe zone. Takes full damage. Party loses 3 morale each. |
| Veteran | Global QTE in dungeon Veteran has cleared | Safe zone prompt appears 0.5s earlier. |
| Speedrunner | Any global QTE | Moves to safe zone immediately — may overshoot and take partial damage anyway. |
| Casual | Hit by any QTE | No morale penalty. Takes the hit. May block safe zone for other members. |
| Min-Maxer | 3+ QTEs missed in one room | Inefficiency Report drama event queued for post-run. Immediate party morale penalty. |

---

## Boss Phases

| Phase | HP Threshold | Pattern |
|---|---|---|
| Phase 1 | 100–66% | Single global QTE per cycle, generous window. Introduces the boss's core pattern. |
| Phase 2 | 65–33% | Global + single-target simultaneously. Boss speed +20%. Aggro breaks more frequently. |
| Phase 3 | 32–1% | Multiple overlapping QTEs. Boss spawns 1–2 adds. A Finisher staggers the boss 2s, pausing all QTEs. |
| Enrage | Timer exceeded | Windows collapse to minimum. Boss ignores threat and targets the Healer directly. |

The enrage timer is visible from the moment the boss room begins. Boss phase patterns are data-driven from `dungeons.ron`.

---

## Flawless Clear

Zero QTE failures across the entire dungeon awards a Flawless Clear bonus on run completion:

- Additional rare+ loot items
- Full party morale boost
- Doubled positive trait reactions from Tryhard and Min-Maxer
- Additional [[reputation|Reputation]] multiplier

---

## Implementation Notes

### Bevy

A QTE is spawned as an entity with position, radius, and a countdown timer component. When triggered, it notifies the UI layer of its world-space position. The UI (egui) renders the safe zone prompt at the projected screen-space position using Bevy's `Camera::world_to_viewport()`.

The player's tap/click resolves the QTE by writing a `QTESolved` event. The countdown timer fires a `QTEFailed` event on expiry if `QTESolved` was not received first. Consequences are applied by a dedicated system reading `QTEFailed` — it applies damage and debuffs to component values and writes `GameEvent`s for the [[traits|trait evaluation system]] to react to.

QTE miss tracking for the Flawless Clear is a simple counter in `ActiveRun`. On run completion, if the counter is zero, a `FlawlessClear` event is written and consumed by the loot and reputation systems.

### Flutter + Flame
QTE entities live in the Flame world as `PositionComponent`s with a `TimerComponent` child for the countdown. When the timer fires without resolution, `DungeonGame` writes a `QTEFailed` event to the `StreamController`.

The player interaction is a Flutter `GestureDetector` — not a canvas tap — positioned at the QTE's world-to-screen projected coordinates via `camera.worldToScreen()`. This gives native platform touch response with zero WebView latency, which matters for timing-sensitive QTE interactions.

The screen-space position is stored in `CombatStateResource` (a Riverpod provider or Cubit watching the `StreamController`) and used to place a `Positioned` Flutter widget above the `GameWidget` canvas. The player taps this widget, which calls `dungeonGame.resolveQTE()` via a passed callback and writes `QTESolved` to the stream.
