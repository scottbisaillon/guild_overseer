# Guild State — Foundations for the Management Loop

The substrate the [[../gameplay-loop|management loop]] moves around: who is in
the guild, what they are carrying, what the guild can spend, and how a roll is
made. Everything here is a value type or a pure function — **nothing in this
document drives anything.** The loop itself is deliberately absent.

**Applies to:** [[../systems/members]], [[../systems/economy]], [[../systems/dungeon]]
**Current code:** `app/lib/src/core/domain/`, `app/lib/src/features/guild/domain/`

---

## What landed

| Type | Where | What it is |
|---|---|---|
| `Meter` | `core/domain/meter.dart` | A 0–100 value that cannot leave its range. Morale, loyalty, fatigue. |
| `Currency`, `Purse` | `core/domain/purse.dart` | An amount of money — held or owed. `spend` answers null rather than going negative. |
| `GameRandom` | `core/domain/rng.dart` | A seeded generator that splits into named streams. |
| `DefinitionIndex<T>` | `core/domain/definition_index.dart` | Id → content, loud when it misses. |
| `ExperienceCurve` | `guild/domain/experience_curve.dart` | What a level costs. Level is derived, never stored. |
| `Member` | `guild/domain/member.dart` | One person in the guild, as a value. |
| `Roster` | `guild/domain/roster.dart` | Everyone, keyed and ordered, with the membership rules. |
| `MemberCondition` | `guild/domain/member_condition.dart` | What morale and fatigue are worth, as stat modifiers. |
| `Deployment` | `guild/domain/deployment.dart` | The one place a member becomes something that can fight. |

---

## The four decisions worth knowing

**A member holds ids, not content.** A member wears `'wardens_shield'`, not a
`ItemDefinition`. That is what keeps a save a list of ids rather than a copy of
the game's content, and it is why nothing above combat imports the battle
layer. Ids become definitions at exactly one point — `Deployment.deploy` — and
that is also where an id naming nothing is caught, with the id in the message.

**Level is derived from experience.** Storing both invites them to disagree,
and the first time they do is in a save somebody has already played fifty hours
of. `Member.level` reads through `ExperienceCurve` on every access.

**Rolls come from named streams.** One shared `Random` would make every
system's sequence depend on how many numbers every *other* system drew first —
add a loot roll and every trait proc for the rest of the run shifts. So:

```dart
final GameRandom run = GameRandom(activeRun.seed);
final GameRandom room = run.fork('room:$index');
final GameRandom loot = room.fork('loot');
```

Nothing serialises a generator's position — the seed and the step index are the
whole of the state, and both are already in the save. This is the same rule the
[[combat-extensibility#Cross-cutting concerns|combat plan]] states for the
fight, extended to everything above it.

**Condition is a stat modifier like any other.** Morale and fatigue reach a
fight as `StatModifier`s granted at spawn, through the pipeline gear and buffs
already use. The combat maths never learns that a guild exists, and retuning
what condition is worth is two constants in one file.

---

## The seams left open

These are where the loop plugs in. Each is a deliberate gap, not an oversight:

- **Dispatch.** `Deployment.deployAll(roster, ids)` hands back blueprints. Who
  is eligible, what a party costs, and what dispatch does to availability is
  the loop's to decide — `MemberAvailability` names the states and nothing
  transitions between them.
- **Run resolution.** No `ActiveRun`, no dungeon definitions, no tick. The
  shapes they need are here: a seed to fork from, a roster to update, a purse
  to pay into.
- **Applying an outcome.** `Roster.updatedAll(partyIds, …)` is the shape a run
  result lands through. What a clear is worth in experience, morale and fatigue
  is balance, and belongs with the run.
- **Persistence.** Every state type round-trips through JSON and tolerates a
  save that names content it no longer has. There is no store and no
  `schemaVersion` yet — that is [[../plan|plan]] task 1.6, and it wants one
  root save object to version, which is the loop's state.
- **Events.** `GameEvent` is still combat-only. Management events (`RunCompleted`,
  `MemberHired`, `LootDropped`) should join that same hierarchy when something
  consumes them — per the combat plan's rule, an event exists when a consumer
  needs to distinguish it.

---

## Deliberately not built

- **No class table.** `CombatRole` stands in for the five classes. A member's
  numbers are authored into `baseStats`; level does not scale them, because
  what a level is worth in stats is a balance decision that belongs with the
  class data rather than a growth curve nobody chose.
- **No traits.** `Member.traitIds` exists so a recruit rolled today is the same
  person once traits land. Nothing reads it. Traits need the reaction seam
  (stage 7 of [[combat-extensibility]]) underneath them.
- **No cubits.** State management is the loop's shape to choose. These are
  values; they will sit inside whatever holds them.
