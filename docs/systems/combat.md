# Combat System — Active Dungeon

The active dungeon is a top-down 2D bounded arena. Party members and enemies move freely using steering behaviours, auto-attack via their [[rotation|skill rotations]] once in range, and respond to [[qte|QTE events]]. Sprites move in eight directions but face left or right only, flipping on the X axis based on velocity direction.

**Depends on:** [[members]], [[traits]], [[rotation]], [[qte]], [[dungeon]]

---

## Movement & Pathfinding

All entities use steering behaviours — no navmesh or grid pathfinding. At the entity counts involved (max 6 party + 12 enemies) manual vector steering is sufficient and gives fluid, natural-feeling movement.

- **Seek** — steers toward the current target each frame.
- **Arrive** — decelerates as it approaches attack range, stopping when the target is within range rather than walking into them.
- **Separation** — entities maintain a minimum distance from each other, causing natural spread without player intervention.
- **Obstacle avoidance** — wall edges deflect movement via an avoidance vector added to the seek direction.
- **Sprite direction** — left-facing spritesheet only; flip X based on horizontal velocity each frame.

When a target dies the entity immediately seeks the next target. Rotation continues from its current position — no cooldown reset on re-target.

---

## Target Priority

Each party member has a configurable priority mode. Cached per member — only re-evaluated on target death or explicit override.

| Priority | Behaviour |
|---|---|
| **Nearest** | Closest enemy by distance. Default for melee DPS. |
| **Weakest** | Enemy with lowest HP percentage. Prioritises finishing kills. |
| **Threat** | Enemy the Tank has highest aggro on. Focuses party. |
| **Strongest** | Highest-HP or highest-damage enemy. Niche use. |
| **Manual** | Player taps an enemy directly. Overrides trait biases until the target dies. |

[[traits|Trait]] biases apply on top of the priority setting and cannot be fully suppressed. See [[traits#Targeting Overrides]].

---

## Enemy AI & Threat

Enemies use the same steering system as party members.

**Threat Table** — each enemy tracks a threat value per party member. The Tank generates significantly more threat via Taunt and Shield Slam. Enemies target the highest-threat member by default.

**Aggro Break** — if a DPS member's threat exceeds the Tank's by a threshold, the enemy re-targets them.

| Enemy Archetype | Priority Bias |
|---|---|
| Melee Add | Nearest member |
| Ranged Construct | Lowest-HP member |
| Debuffer | The Healer specifically |
| Boss | Highest-threat member + scripted ability patterns on a separate timer |

Bosses combine threat-based movement with scripted [[qte|QTE patterns]]. A boss walks toward the Tank while simultaneously charging an AoE aimed at the Healer.

---

## Attack Range & Rotation Firing

When an entity closes to within its attack range, it stops seeking and begins firing its [[rotation|rotation]]. When the target dies or moves out of range, seeking resumes.

| Role | Range |
|---|---|
| Tank / Melee DPS | Close melee range |
| Ranged DPS / Support | Configurable stand-off distance |
| Healer | Stays within heal range of the party cluster — not an enemy |

---

## Room Boundary

Each dungeon room is a fixed-size bounded arena defined in `dungeons.ron`. The camera is static within the room. The party transitions to the next room once all enemies are cleared.

---

## Implementation Notes

### Bevy

Each entity carries `Velocity`, `CurrentTarget`, and `Transform` components. The steering system reads these each frame and writes a new velocity. A separate movement system applies velocity to `Transform` — keeping query sets non-conflicting.

The `InRange` component is a zero-sized marker added and removed by a range detection system each frame. The rotation firing system is gated on `With<InRange>` — entities not in range produce no skill events.

Enemy threat is tracked in a per-enemy `ThreatTable` component (map of entity ID to threat value). Updated by a threat system reading `SkillFired` and `TauntUsed` events. The enemy targeting system reads the threat table to select its current target.

System ordering matters: targeting → steering → range detection → rotation firing → threat update → trait evaluation. Declare this ordering explicitly using Bevy's system ordering API (`.after()` or system sets).

### Flutter + Flame
The Flame `DungeonGame` is a `FlameGame` embedded as a `GameWidget` inside the `ActiveRunScreen` Flutter widget via a `Stack`. All HUD elements sit above the canvas as Flutter `Positioned` widgets.

Each entity is a `PositionComponent` subclass (`MemberComponent`, `EnemyComponent`). Steering behaviours are computed in each component's `update(double dt)` — seek toward `currentTarget.position`, arrive deceleration within `attackRange`, separation from nearby entities. `Vector2` arithmetic from the `flame` package handles all math.

The `InRange` state is a boolean on each component, toggled by a range check in `update(dt)`. When in range, `velocity = Vector2.zero()` and the rotation begins accumulating `dt` against cooldowns.

All game events are written to a `StreamController<GameEvent>.broadcast()` owned by `DungeonGame`. `GameBloc` subscribes via `_dungeonGame.events.listen(add)` — making `GameEvent` sealed class instances serve directly as Bloc events with no translation layer needed. System ordering is managed by call order within each component's `update(dt)`.
