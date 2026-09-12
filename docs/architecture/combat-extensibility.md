# Combat Extensibility — Architecture Plan

How the battle systems should be shaped so that adding a skill, an effect, a
buff, a piece of gear, or a visual is **authoring data**, not editing combat
code.

**Applies to:** [[../systems/combat]], [[../systems/skills]], [[../systems/rotation]], [[../systems/traits]], [[../systems/loot]]
**Current code:** `app/lib/src/features/battle/domain/`

---

## Where we are

The prototype is already well-layered — rules are pure Dart, presentation reads
the simulation and never writes back, and everything the fight decides leaves
through one `Stream<GameEvent>`. That split is the expensive part and it is
already right. What is not yet right is the *shape of a skill*.

Today `SkillDefinition` is a fixed record:

```dart
SkillKind kind;          // damage | heal
SkillDelivery delivery;  // melee | projectile | beam
SkillTargeting targeting;// opposingPriority | opposingColumn | lowestHealthAlly
double power;
```

Three closed enums, each switched on in a different layer:

| Enum | Switched in |
|---|---|
| `SkillKind` | `battle_simulation.dart` (`_fire`), `battle_game.dart` (`_onSkillFired`) |
| `SkillTargeting` | `targeting.dart` (`resolveSkillTargets`) |
| `SkillDelivery` | `battle_game.dart`, `unit_component.dart` |

Consider the smallest realistic next piece of content: **"Rend applies a bleed
for 12 damage every 2s for 6s, and the bleed ticks harder on a target below
50% HP."** In the current shape that requires:

1. A new `SkillKind` value, and an arm in the simulation's `switch`.
2. Somewhere to store per-target ongoing state — the `Combatant` has no such
   field.
3. A new `GameEvent` for the tick, plus arms in the Bloc, the Flame layer, and
   the two exhaustive `switch`es in `battle_game.dart`.
4. A new `SkillDelivery` value if the bleed should look like anything.

Four files, three of them nowhere near "skills", for one piece of content. That
is the cost curve to flatten. Similarly, there is no stat layer at all — a
`Combatant` has `maxHealth` and nothing else — so "a sword grants +12 attack
power" and "War Cry grants +10% melee damage" currently have nowhere to land.

---

## Principles

These are the rules the rest of the document follows. They are worth more than
any specific class shape below.

1. **Content is data; code is the interpreter.** A skill is a list of effects
   with selectors, not a branch in a method. New content adds rows; new
   *mechanics* add code — and that ratio should be roughly 20:1.
2. **One switch per concept, in one place.** A closed set (effect kinds, for
   instance) is fine — Dart 3 `sealed` types make the compiler list every site
   you must update. What is not fine is the *same* set being switched on in the
   simulation, the renderer, the Bloc, and the HUD. Presentation binds to
   authored ids, never to rule enums.
3. **One pipeline, many sources.** Buffs, gear, auras, traits and passives must
   not each grow their own path into a unit's numbers. They all emit the same
   `StatModifier`, tagged with where it came from, and removal is by source.
4. **Composition over enumeration.** Targeting is four small orthogonal choices
   (side × anchor × shape × ordering), not one enum that grows a case per
   skill. Combinatorial coverage with no new code is the goal.
5. **Fail loudly at load, softly at render.** A missing skill id is a content
   bug and should crash the loader with the id in the message. A missing *visual
   cue* id should assert in debug and fall back to a default in release — a
   cosmetic gap must never end a run.
6. **Determinism is a feature.** The seeded simulation is what makes
   `tool/simulate_battle.dart` and the tests possible. Every new system that
   rolls dice must draw from the same threaded source, and the golden test
   (below) is what keeps that honest.

---

## The seams

Seven of them. Each is independently useful, and the migration section orders
them so that every stage ships.

### 1. Stats and the modifier pipeline

This lands first because effects scale off stats and gear grants stats — both of
the user-facing asks ("buffed by skills, but also by equipped items") reduce to
this one mechanism.

```dart
enum Stat {
  maxHealth, attackPower, healPower, armour, magicResist,
  critChance, critMultiplier, cooldownRate, globalCooldown,
  threatMultiplier, damageTakenMultiplier,
}

enum ModOp {
  flat,       // +12 attack power          — summed
  increased,  // +10% melee damage         — summed, then applied once
  more,       // x1.5 (rare, multiplicative — for big swingy effects)
}

class StatModifier {
  final Stat stat;
  final ModOp op;
  final double value;
  final ModifierSource source;   // what to remove it with
  final TagSet? appliesTo;       // optional: only vs `physical`, only `bleed`, ...
}

class ModifierSource {
  final ModifierSourceKind kind; // item | status | aura | trait | passive
  final String id;               // 'item:weapon', 'status:war_cry', 'trait:glass_cannon'
}
```

Evaluation order, fixed and documented so balance is predictable:

```
value = (base + Σflat) × (1 + Σincreased) × Π(1 + more)
```

Two `increased` modifiers of +10% give +20%; two `more` modifiers of +10% give
+21%. Keep `more` rare — reserve it for capstones and legendaries. `StatBlock`
caches computed values behind a dirty flag, invalidated whenever a modifier is
added or removed.

The payoff is that **equipping an item and gaining a buff are the same
operation**:

```dart
unit.stats.addAll(sword.modifiers, source: ModifierSource.item(Slot.weapon));
unit.stats.addAll(warCry.modifiers, source: ModifierSource.status('war_cry'));
// and removal never needs to know which was which:
unit.stats.removeBySource(ModifierSource.item(Slot.weapon));
```

`maxHealth` becomes a stat rather than a constructor field, which means gear
that grants HP works without touching the simulation. Current health stays a
plain mutable field; when max health changes, preserve the *fraction* rather
than the absolute (a helm swap mid-fight shouldn't heal you).

### 2. Skills as lists of effects

Replace `kind` + `power` with a list:

```dart
class SkillDefinition {
  final String id;
  final String name;
  final double cooldown;
  final bool isBasic;
  final List<EffectSpec> effects;     // ordered; resolved in order
  final PresentationSpec presentation;
  final TagSet tags;                  // melee, physical, aoe, finisher, ...
}

class EffectSpec {
  final TargetSelector selector;      // who this one lands on
  final SkillEffect effect;           // what happens to them
}
```

One skill, several effects, each with its *own* selector — which is what makes
"Reckless Strike: heavy damage to the target, 10% of it back to yourself"
expressible without a special case.

The effects themselves are a sealed hierarchy of plain data:

```dart
sealed class SkillEffect { const SkillEffect(); }

final class DamageEffect extends SkillEffect {
  final double coefficient;   // multiplied by the caster's scaling stat
  final Stat scalesWith;      // attackPower
  final DamageType type;      // physical | magic | true
  final double variance;      // 0.15 — today's ±15% roll, now per-effect
}

final class HealEffect       extends SkillEffect { ... }
final class ApplyStatus      extends SkillEffect { final String statusId; final int stacks; }
final class RemoveStatus     extends SkillEffect { final TagSet matching; final int count; }
final class ShieldEffect     extends SkillEffect { ... }
final class ThreatEffect     extends SkillEffect { ... }
final class ForceTarget      extends SkillEffect { final double duration; }  // Taunt
final class ResourceEffect   extends SkillEffect { ... }
```

Note `power: 62` becomes `coefficient: 1.6, scalesWith: attackPower`. That one
change is what makes gear matter: a sword's +12 attack power flows into every
skill that scales off it, automatically, with no per-skill bookkeeping.

**Resolution lives in exactly one file.** `EffectResolver` holds a single
exhaustive `switch` over the sealed type:

```dart
void resolve(EffectSpec spec, ResolutionContext ctx) {
  for (final Combatant target in resolveTargets(spec.selector, ctx)) {
    switch (spec.effect) {
      case DamageEffect e: _resolveDamage(e, target, ctx);
      case HealEffect e:   _resolveHeal(e, target, ctx);
      case ApplyStatus e:  target.statuses.apply(e.statusId, e.stacks, ctx);
      // ... compiler-enforced exhaustive
    }
  }
}
```

> **Trade-off, stated deliberately.** The alternative is polymorphic effects —
> each subclass carrying its own `apply()`. It is tempting and it is worse here:
> every effect would need the whole simulation injected (all units, the RNG, the
> event sink) to do its job, serialization gets murkier, and combat rules end up
> spread across twenty small files instead of one readable one. Keep effects as
> **data**, resolution as **one interpreter**. A `Map<Type, EffectHandler>`
> registry is the escape hatch if plugin-authored effects ever become a goal;
> it trades the compiler's exhaustiveness check for open extension, and that
> trade is not worth making while this is a single codebase.

`ResolutionContext` is the one bundle passed everywhere: caster, all units, the
layout, the RNG, the event sink, and the current recursion depth.

### 3. Targeting as a composable selector

`SkillTargeting` (three cases) and `TargetPriority` (six cases) are today two
enums expressing the same idea in different vocabularies. Fold them into one
value object:

```dart
class TargetSelector {
  final TargetSide side;     // self | allies | enemies | all
  final TargetAnchor anchor; // caster | currentTarget | effectSource | statusSource
  final TargetShape shape;   // single | sameColumn | sameRow | adjacent | all | random
  final TargetOrder order;   // nearest | lowestHealthFraction | highestMaxHealth
                             // | frontline | backline | highestThreat | preferRole
  final List<TargetFilter> filters;  // alive, wounded, hasTag('bleed'), role(healer)
  final int count;           // 1 for single target; n for "three random enemies"
  final bool includeSelf;
}
```

Every case in today's code falls out of the combination, and so do a great many
that do not exist yet:

| Skill | Selector |
|---|---|
| Shield Slam | `enemies, anchor: currentTarget, single` |
| Cleave | `enemies, anchor: currentTarget, sameColumn` |
| Mend | `allies, order: lowestHealthFraction, filters: [wounded], count: 1` |
| War Cry | `allies, shape: all, includeSelf: true` |
| Purify | `allies, filters: [hasTag(debuff)], count: 1` |
| Chain Lightning | `enemies, anchor: currentTarget, order: nearest, count: 3` |
| Execute | `enemies, filters: [healthBelow(0.15)], count: 1` |

A unit's configured `priority` collapses to "the `TargetOrder` used when this
unit acquires a target" — one concept, used in two places, instead of two
concepts that must be kept in sync.

Preserve today's important behaviour: **an empty selection means the skill is
skipped and the rotation falls through**. That is what stops a healer burning
its beat on a no-op, and it generalises for free — a Cleanse with nothing to
cleanse behaves the same way. Expose it as `Skill.requiresTargets` so a
self-buff with no valid target can still fire if authored to.

Trait targeting biases (see [[../systems/traits#Targeting Overrides]]) then
become *score adjustments* applied to the ordering, rather than overrides that
replace it — which matches the design intent that they "cannot be fully
suppressed".

### 4. Status effects — where buffs, debuffs and DoTs live

```dart
class StatusDefinition {
  final String id;
  final String name;
  final double duration;
  final int maxStacks;
  final StackPolicy policy;              // refresh | stack | independent
  final List<StatModifier> modifiers;    // feeds seam 1 while active
  final List<EffectSpec> onApply;
  final List<EffectSpec> onTick;         // a DoT is just this
  final double tickInterval;
  final List<EffectSpec> onExpire;
  final TagSet tags;                     // debuff, bleed, physical, magic, curse
  final PresentationSpec presentation;
}
```

Two things make this carry real weight:

**Ticks re-enter the same resolver.** A bleed's periodic damage is an
`EffectSpec` resolved by `EffectResolver`, exactly like a skill's. It therefore
crits, scales, respects armour, emits the same events, and logs the same way —
with zero duplicated damage code. The whole Rend-applies-a-bleed example becomes
two data rows and no new code.

**Tags make effects talk about each other without naming each other.** "Purify
removes one debuff" is `RemoveStatus(matching: {debuff}, count: 1)`. "Fortify:
-15% physical damage taken" is a `StatModifier` with `appliesTo: {physical}`.
Neither needs to enumerate the statuses or skills it interacts with, so content
added later is covered automatically.

On scaling: **snapshot the caster's stat at application time** and store the
resolved magnitude on the active status. It is deterministic, it survives the
caster dying mid-DoT, and it avoids the surprise of a bleed changing strength
when someone else's buff expires. (Dynamic recalculation is the other valid
choice; it is just harder to explain in the combat log.)

`StatusContainer` lives on the `Combatant`, ticks in the simulation's step, and
adds/removes its modifiers from `StatBlock` under `ModifierSource.status(id)` —
so expiry cleanup is one call, not a bespoke undo per buff.

Auras are statuses that a system continuously reapplies to everyone matching a
selector, rather than a separate mechanism. Reapplying with `StackPolicy.refresh`
each tick gives correct behaviour when a unit dies or the aura's owner falls.

### 5. Triggers and reactions

One mechanism covers Reactive skills, trait reactions, item procs, and Finisher
sequences — all of which are "when X happens, and conditions hold, resolve
effects":

```dart
class Reaction {
  final String id;
  final TriggerSpec trigger;        // keyed off the existing GameEvent hierarchy
  final List<Condition> conditions;
  final List<EffectSpec> effects;
  final double? internalCooldown;   // per-reaction, prevents machine-gunning
  final int? maxPerBattle;
}
```

`TriggerSpec` examples: `onDamageTaken`, `onAllyHealthBelow(0.3)`,
`onUnitDied(faction)`, `onStatusApplied(tag: debuff)`,
`onSkillSequence(['taunt', 'shield_slam'])` — that last one is how Finishers work,
matched against a sliding window of recently-fired skill ids already described in
[[../systems/skills#Implementation Notes]].

> **The one genuinely dangerous seam.** Reactions can trigger effects that
> trigger reactions. Two units with damage-reflect will loop forever and hang the
> game loop.
>
> Three guards, all mandatory:
> 1. **Never resolve a reaction recursively inside effect resolution.** Push to a
>    queue and drain it after the current effect batch completes.
> 2. **Cap cascade depth** (4 is generous) in `ResolutionContext`; drop and log
>    beyond it in debug builds.
> 3. **Dedupe by `(reactionId, unitId, tick)`** so one reaction fires at most
>    once per unit per tick regardless of how many events matched.
>
> These are cheap to write now and very expensive to retrofit after content
> depends on the loose behaviour.

### 6. Presentation binding

The renderer must stop switching on rule enums. Skills and statuses carry an
authored cue instead:

```dart
class PresentationSpec {
  final String castCueId;    // 'lunge', 'cast_arcane', 'channel_beam'
  final String? travelCueId; // 'arrow', 'fireball', 'shadow_bolt'
  final String? impactCueId; // 'slash_spark', 'heal_bloom'
  final String? statusCueId; // persistent overlay while a status is active
  final ColorRole colorRole; // damage | heal | shield | debuff — palette lookup
}
```

The Flame layer owns a registry, populated once at startup:

```dart
class CueRegistry {
  final Map<String, CueBuilder> _builders;
  void register(String id, CueBuilder builder);
  Component? build(String id, CueContext ctx);  // null + debug assert if unknown
}
```

`battle_game.dart`'s `switch (event.delivery)` disappears. Adding a new visual
becomes: write a `Component`, register it under an id, reference that id from
data. Nobody edits the simulation to add a particle effect, and nobody edits the
renderer to add a skill.

The same idea applies to the combat log: events should carry structured fields
(source, target, magnitude, tags, cue) and the Bloc should hold *one* formatter,
rather than a bespoke string per event type as it does now.

### 7. Content, ids, and validation

Definitions move to JSON assets behind a `ContentRepository`, exactly as
[[../milestones/11-data-driven-skills]] describes, extended to statuses, items,
classes and reactions. Two rules beyond that milestone:

- **A single materialization function per content type.** Data shape and runtime
  shape are allowed to differ; one factory translates. Consumers never see the
  JSON.
- **A validation pass at load** that walks every definition and asserts every
  referenced id resolves — skill → status, status → effect → status, item →
  modifier stats, reaction → skill. Run it as a test over the shipped content
  files, so a typo fails CI rather than a playtest.

---

## The three examples, end to end

Checking the architecture against exactly what was asked.

**"A unit will have multiple skills, each having different effects, both
functional and visual."** A skill is `List<EffectSpec>` + `PresentationSpec`.
Functional variety comes from the sealed effect set (closed, small, one switch);
visual variety comes from cue ids resolved through a registry (open, no switch).
A skill that damages, applies a bleed, and grants the caster a shield is three
`EffectSpec`s with three selectors and no new code.

**"They may have different targeting."** Each `EffectSpec` carries its own
`TargetSelector`, so the damage can hit the target's column while the shield
lands on the caster. The selector is composed from four orthogonal axes, so the
combinations available to designers vastly outnumber the code paths.

**"A unit's stats may be buffed by skills, but also by equipped items."** Both
emit `StatModifier`s into one `StatBlock`, distinguished only by
`ModifierSource`. A skill's buff is a status whose modifiers are added on apply
and removed on expiry; an item's is added on equip and removed on unequip. The
combat maths never asks where a number came from — and the HUD can show the
breakdown by grouping modifiers by source, which is the tooltip players want
anyway.

---

## Cross-cutting concerns

**Determinism.** Every roll — variance, crit, proc chance, random target
selection — must draw from the RNG threaded through `ResolutionContext`, never
from an ad-hoc `Random()`. Add a golden test that runs the mock roster to
completion and asserts a hash of the full event stream. It is three lines of
test code and it is the only thing that will catch an accidental reordering of
resolution that silently changes every fight.

**Step ordering, written down.** With more systems, "what happens first" stops
being obvious. Fix it and document it in `battle_simulation.dart`:

```
tick statuses (durations, periodic effects)
  → tick cooldowns
  → drain reaction queue
  → acquire targets
  → select skills
  → resolve effects
  → drain reaction queue
  → resolve deaths
  → check end condition
```

Deaths resolve at the end of the step, so two units that kill each other on the
same beat both land their blows — consistent, and it removes today's subtle
"a unit killed earlier in this same step does not get to act" ordering
dependency on roster order.

**Event hierarchy growth.** Resist one `GameEvent` subclass per effect kind — it
would push the same combinatorial explosion into the Bloc and the renderer.
The rule: **an event exists when a consumer needs to distinguish it**. Damage and
healing stay separate (distinct log colours, distinct floating text); shields,
statuses and threat changes fold into a small number of generic events carrying
tags.

**Save/load.** Definitions are referenced by id; only runtime state serialises —
remaining cooldowns, active statuses with remaining durations and stacks,
equipped item instance ids, current health. Add a `schemaVersion` from the first
save, per [[../plan]] task 1.6.

---

## Migration sequence

Each stage compiles, passes tests, and leaves the game playable. Ordered by
dependency, and deliberately front-loaded with the least glamorous work.

| # | Stage | Why here | Rough size |
|---|---|---|---|
| 0 | **Golden test of the current fight** | A safety net *before* any refactor. Asserts a hash of the event stream from the mock roster. | XS |
| 1 | **`Stat`, `StatBlock`, `StatModifier`** | Effects scale off stats; everything downstream needs this. `maxHealth` becomes a stat. No behaviour change — golden test must still pass. | M |
| 2 | **Effect lists** | `kind`+`power` → `List<EffectSpec>`; damage and heal become effects; `power` becomes `coefficient × stat`. Golden test changes once, intentionally, and is re-pinned. | L |
| 3 | **Composable targeting** | Fold `SkillTargeting` and `TargetPriority` into `TargetSelector`. Pure refactor with a large payoff in authoring freedom. | M |
| 4 | **Statuses** | First stage that adds *new* mechanics. Ship Rend→bleed and Fortify as proof. | L |
| 5 | **Presentation registry** | Delete the `SkillDelivery` switches; cue ids in data. Unblocks art without touching rules. | M |
| 6 | **Equipment** | `ItemDefinition` → modifiers under `ModifierSource.item`; gear slots on the unit. Small, because seam 1 already did the work. | S |
| 7 | **Reactions** | Depends on statuses, effects and the event bus being settled. Traits, Reactive skills and Finishers all land here together. | L |
| 8 | **Content to JSON + validation** | Last, so the schema is written against a shape that has stopped moving. | M |

Stages 1–3 are refactors of existing behaviour and should be verifiable by the
golden test alone. Stage 4 is the first point at which the investment pays
visible dividends, and is a good checkpoint to reassess before continuing.

---

## Test strategy

- **Golden fight test** — hash of the event stream from a fixed roster and seed.
  Catches accidental changes to ordering, RNG draw order, or resolution.
- **One unit test per effect kind** — resolve it against a hand-built context,
  assert the numbers. Cheap, and they are the regression net when the resolver
  grows.
- **Selector table test** — a parameterised test over a fixed twelve-unit board
  asserting which units each selector shape returns. This is where off-by-one
  targeting bugs get caught.
- **Modifier pipeline test** — that `flat`/`increased`/`more` compose in the
  documented order and that removal by source is exact.
- **Reaction cascade test** — two units with damage-reflect must terminate.
  Assert the depth cap holds.
- **Content validation test** — load every shipped data file, assert every id
  resolves. Fails CI on a typo.

---

## What not to build

Scope discipline matters more than any of the above, so being explicit:

- **No embedded scripting language.** Lua or an expression evaluator for skill
  effects sounds like maximum extensibility and delivers unreviewable content,
  no compile-time checking, and a debugging surface with no floor. The sealed
  effect set plus composable selectors covers the entire design doc's catalogue.
- **No ECS rewrite.** The current layering already gives the benefit that
  motivates ECS here — rules separated from rendering. A rewrite costs weeks and
  buys nothing this design needs.
- **No general-purpose modding API.** If mods become a goal, the effect registry
  escape hatch in seam 2 is the hook. Designing for it now adds indirection
  nobody is using.
- **No effect subclass polymorphism.** Covered in seam 2 — it scatters combat
  rules and complicates serialization for no gain.
- **No premature generic "buff system" ahead of stage 4.** Statuses need the
  stat pipeline and the effect resolver underneath them; built first, it will be
  rewritten.
