# Dungeon System

Dungeons are defined rooms the party enters and clears. Each run is a sequence of rooms ending with a boss. Runs resolve in Active or Idle mode depending on whether the player character is in the party. See [[../early-game#Active vs Idle — The Defining Mechanic]].

**Depends on:** [[members]], [[traits]], [[rotation]], [[loot]], [[reputation]]

---

## Dungeon Roster

Higher-tier dungeons require accumulated [[reputation|Reputation]] to unlock.

| Dungeon | Levels | Difficulty | Enemy Type | Party Size | Loot Pool |
|---|---|---|---|---|---|
| The Hollow Crypt | 1–5 | Easy | Undead | 2–3 | Common gear, copper |
| Fungal Warrens | 5–10 | Easy | Myconid | 3–4 | Alchemical reagents, rare herbs |
| Ironclad Bastion | 10–20 | Medium | Constructs | 4–5 | Uncommon armor, blueprints |
| Sunken Vault | 20–35 | Medium | Aquatic | 4–6 | Rare loot, enchanted items |
| Crimson Spire | 35–50 | Hard | Demons | 5–6 | Epic gear, boss drops |
| The Obsidian Labyrinth | 50+ | Legendary | Void entities | 6 | Legendary items, prestige mats |

---

## Room Types

| Room Type | Description |
|---|---|
| **Combat** | Standard enemy encounters resolved by auto-battle |
| **Elite** | Tougher variants with guaranteed uncommon+ loot |
| **Trap** | Require Reactive skills or Support role to navigate safely |
| **Loot** | Optional; accessible via hidden routes (Completionist trait helps) |
| **Rest** | Reduce fatigue and restore morale mid-run |
| **Boss** | Final encounter; multi-phase; guaranteed rare+ loot chest |

---

## Party Requirements

Violations apply stacking penalties rather than blocking dispatch. Shown on [[../ui/party-composer|Party Composer]] before confirming.

| Violation | Penalty |
|---|---|
| No Healer | Party takes 50% more damage; wipe risk increases |
| No Tank | Front-line members take direct hits; fatigue spikes faster |
| No DPS | Combat rooms take 3× longer; fatigue escalates |
| Overloaded role | Morale penalty; minor performance debuff |

---

## Idle Resolution

The idle tick advances the run at a rate configured per dungeon in `dungeons.ron`. Each tick:

1. Resolve the current room type via stat formulas
2. Apply [[traits|trait]] modifiers and probability rolls
3. Apply [[rotation#RQS|RQS]] as a multiplier on combat outcomes
4. Emit room result events
5. Advance room index; check for drama event triggers

Drama events fire mid-run — not only at the end. A Drama Queen + Loot Goblin conflict triggers a run pause and a drama event requiring player resolution.

**Offline progression:** on app resume, elapsed time is computed from a stored timestamp. The engine fast-forwards idle runs up to an 8-hour cap, then presents a summary of what happened.

---

## Data Definition

All dungeon properties live in `dungeons.ron`: room pool, room tick rate, boss phases, QTE patterns per phase, party requirements, loot table references. No dungeon behaviour is hardcoded in systems.

---

## Implementation Notes

### Bevy

The active run state lives in a `Resource` (`ActiveRun`) holding the dungeon ID, current room index, party entity list, run timer, seed (for deterministic idle resolution), and a flag for whether this is an active or idle run.

The idle tick system runs in `Update`, gated by `if !active_run.is_active`. When active, the [[combat|combat system]] drives resolution instead. Both paths emit the same room result events downstream — [[loot]], [[traits]], and [[reputation]] systems are unaware of which mode ran.

The run timer is a Bevy `Timer` component advanced by `Res<Time>`. Offline fast-forward computes `elapsed = now - last_saved_at` in a `Startup` system and calls the tick logic in a loop up to the cap.

### Flutter + Flame
The active run state lives in `ActiveRun` — a plain Dart model stored in `GuildCubit` state. It holds the dungeon ID, current room index, party member IDs, a run seed for deterministic idle resolution, a timestamp for offline delta, and an `isActive` flag.

The idle tick runs on `dart:async` `Timer.periodic` inside `GuildCubit` — not on the Flame game loop. When `isActive` is false, the timer advances the run, evaluates rooms, and emits `GameEvent`s for `GameBloc` to process. Active runs are driven by the Flame `DungeonGame` instead.

Offline fast-forward computes `elapsed = DateTime.now().difference(lastSavedAt)` in `initState` and loops the idle tick logic up to the 8-hour cap before starting the live timer. Hive persists `ActiveRun` between sessions.
