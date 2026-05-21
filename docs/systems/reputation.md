# Reputation System

Reputation is a cumulative permanent score that gates recruit quality, dungeon tier unlocks, and the guild founding threshold. It is never spent — reaching milestones is a one-way progression.

**Depends on:** [[dungeon]], [[qte]], [[members]], [[../early-game]]

---

## Earning Reputation

Earned from dungeon runs based on run quality — not simply whether it completed.

| Factor | Weight | Detail |
|---|---|---|
| **Rooms Cleared** | 30% | Proportion of total rooms completed. Full clear = maximum. Early wipe = near zero. |
| **QTE Success Rate** | 25% | Percentage of [[qte\|QTE]] events resolved correctly. Flawless Clear grants a bonus multiplier. |
| **Party Survival Rate** | 20% | Proportion of members who returned without a wipe. Revived members count as partial. |
| **Dungeon Tier** | 15% | Higher-tier dungeons award more base reputation. Running below level awards reduced reputation. |
| **Active Run Bonus** | 10% | Active runs award 10% additional reputation over equivalent idle runs. |

Failed runs award reduced or zero reputation depending on how early the wipe occurred.

---

## Milestones

Reputation thresholds and exact values are tuning variables defined in `game_config.ron`.

| Milestone | Effect |
|---|---|
| Starting | Hollow Crypt and Fungal Warrens accessible |
| Tier 2 | Shared tavern pool quality improves. Ironclad Bastion unlocked. |
| Tier 3 | Sunken Vault unlocked. |
| **Guild Founding** | Option to found a guild becomes available. See [[../early-game#Founding the Guild]]. |
| Tier 4 (post-guild) | Crimson Spire unlocked. Guild Tavern pool improves. |
| Tier 5 | Obsidian Labyrinth unlocked. |

---

## Future Sources

> [!note] Future System — Additional Reputation Sources
> Phase 3 adds NPC contracts, world events, and rival guild encounters. The five-factor formula remains but the eligible events expand. See [[../roadmap]].

---

## Implementation Notes

### Bevy

Reputation lives in `Res<Currencies>` as a `f32` — never decremented. The calculation is a pure function over the five factors, making it easy to unit-test with `cargo test` in isolation.

A `reputation_system` reads `EventReader<RunCompleted>`, calls the calculation, updates the resource, and checks for milestone crossings — emitting a `ReputationMilestoneReached` event consumed by the dungeon unlock system and the guild founding prompt.

### Flutter + Flame
Reputation is a `double` field on `EconomyCubit` state — never decremented. The five-factor calculation is a pure Dart function called by `GuildCubit` after each `RunCompleted` event, returning a `ReputationGain` object.

`EconomyCubit.addReputation(gain)` updates the value and checks milestone thresholds, emitting a `MilestoneReached` event that the dungeon unlock system and guild founding prompt respond to. All milestone thresholds are defined in `game_config.json` loaded by `DataRepository`.
