# Rotation System

A rotation is an ordered sequence of up to six Active [[skills|skills]] configured in the [[../ui/skill-editor|Skill Editor]]. During dungeon runs the rotation fires top-to-bottom on repeat, skipping any skill still on cooldown. Passive, Reactive, and Aura skills are always live and do not occupy slots.

**Depends on:** [[skills]], [[traits]], [[dungeon]]

---

## How Rotations Fire

Rotations fire automatically in both Active and Idle mode — the player's role is pre-run configuration, not mid-fight input.

- Skills fire in slot order (1→2→3→4→5→6→1...), skipping any skill on cooldown.
- Dead time between casts when all skills are on cooldown — this is the primary thing RQS measures.
- Rotation begins only once a member is in attack range of a target. See [[combat#Attack Range & Rotation Firing]].
- Rotation state persists through target switches and movement — no reset on re-target.

---

## Rotation Quality Score (RQS)

Every rotation is evaluated against the target dungeon before dispatch. Score from 0–100.

| Factor | Weight | Description |
|---|---|---|
| **Cooldown Coverage** | 30% | How well cooldowns interlock to minimise dead time. |
| **Role Fulfilment** | 30% | Whether the rotation prioritises the member's primary role. A Tank rotation heavy on DPS skills scores lower than one focused on threat. |
| **Finisher Availability** | 20% | Whether prerequisite skills for Finishers appear in the rotation in the correct order. |
| **Dungeon Contextual Fit** | 20% | Trap Rooms reward Reactive skills; Boss phases reward Finishers; Elite Rooms reward burst DPS. |

| RQS | Rating | Outcome |
|---|---|---|
| 90–100 | Optimal | Full output. Finishers proc reliably. Morale boost to Tryhard and Min-Maxer. |
| 70–89 | Efficient | Minor cooldown gaps. No penalties. |
| 50–69 | Suboptimal | Noticeable dead time. Some Finishers fail. DPS/HPS reduced up to 15%. |
| 30–49 | Poor | Frequent idle gaps. 20–30% performance penalty. Trait reactions begin. |
| 0–29 | Broken | Severe penalty. High trait reaction risk. Wipe probability increases. |

---

## Trait Reactions to RQS

| Trait | Trigger | Reaction |
|---|---|---|
| Tryhard | Own RQS below 60 | Morale −10 per run. Build Review event after two consecutive poor runs. |
| Tryhard | Own RQS 90+ | Morale +8. Bonus guild XP. May inspire nearby Casual member. |
| Min-Maxer | Any party member RQS below 50 | Refuses to re-queue with that member until rotation is corrected. Drama event queued. |
| Min-Maxer | Full party RQS 85+ | Party-wide +5% loot quality. |
| Casual | Own RQS below 40 | No personal morale penalty. Low output may frustrate Tryhard teammates. |
| Glass Cannon | Finisher not in rotation | Damage −20%. Flagged in pre-dispatch RQS warning. |
| Veteran | Party average RQS below 55 | Background coaching event gradually raises lower-RQS members over time. |
| AFK Prone | Any RQS | Occasional AFK skip wastes one rotation cycle at random regardless of score. |
| Speedrunner | 6-slot rotation | Refuses to execute last 1–2 skills. Build 4–5 slot rotations for Speedrunners. |

---

## Implementation Notes

### Bevy

The rotation state per member is a component: ordered list of skill IDs, current index, cooldown accumulator, and a sliding window of recently-fired skills for finisher detection.

The rotation firing system runs every frame in `Update`, gated by the `InRange` marker component (added/removed by the range detection system — see [[combat#Bevy Notes]]). It accumulates `delta_seconds()` against cooldowns and writes a `SkillFired` event when a skill is ready.

RQS evaluation is a pure function — no ECS dependencies, fully unit-testable with `cargo test`. Called in the [[../ui/skill-editor|Skill Editor]] each frame for the live preview, and once at dispatch time to store the score in the `ActiveRun` resource.

### Flutter + Flame
Rotation state per member is a field on the `Member` model: ordered list of skill IDs, current index, cooldown accumulator as a `double`, and a `Queue<SkillId>` for finisher detection.

`rotation_evaluator` is a pure Dart function — no Flame or Flutter dependencies. It is called in the [[../ui/skill-editor|Skill Editor]] widget on every build for the live preview, and once at dispatch time, storing the result in `ActiveRun`.

In the Flame active dungeon, `MemberComponent.update(dt)` accumulates `dt` against cooldown values and writes `SkillFired` to the `StreamController<GameEvent>`. The `GameBloc` receives this and updates combat state. See [[combat#Flutter + Flame Notes]].
