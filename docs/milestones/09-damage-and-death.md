# Milestone 9: Damage and death

## Goal

When a skill fires, damage is communicated as an event/signal that multiple consumers can react to independently. Health depletes. Units die at zero health and are removed from the scene. Surviving combatants whose target died re-acquire a new target and the fight continues until one faction is wiped out.

## Scope

- A **damage event** with: source, target, amount.
- A **death event** with: the dying unit (and optionally its faction).
- A consumer that applies damage to the target's health.
- A consumer that checks for death and removes dead units.
- A consumer that detects when other units' targets have died and clears their stored target so they re-acquire.
- Health as a per-unit property (current + max).

## Design Decisions

- **Damage flows through an event, not a direct method call.** When a skill resolves, it *announces* damage. Anything that cares — health subtraction, future damage numbers, future sounds, future telemetry — independently reacts. None of those consumers needs to know about the others.
- **One source of damage application.** There's exactly one consumer that decrements health from a damage event. Multiple consumers can react to the event, but only one *applies* it.
- **Death is also an event.** When health reaches zero, the unit emits a death event before being removed. Other systems (the target-cleanup consumer below) listen to it.
- **Dangling target references get cleaned reactively.** When a unit dies, anyone who was targeting it has their target cleared. The targeting routine (from milestone 4) picks them up the next frame and assigns a new target.
- **Order of operations matters.** Within one frame: skills fire → damage events emitted → damage applied → health checked → death events emitted → target cleanup runs. These should be chained, not allowed to interleave arbitrarily.
- **Recursive cleanup.** When a unit is removed, its owned skill objects go with it. No leaked objects, no manual loop to delete child skills.

## Observable Behavior

- Enter gameplay; let the fight run.
- Health visibly drops (visible via debug inspection until the next milestone adds health bars).
- Units disappear when their health hits zero.
- After a kill, the surviving attackers immediately re-target the next nearest opponent.
- Eventually, one faction is completely gone and the fight resolves.

## Out of Scope

- Visual feedback (next milestone).
- Damage modifiers — crits, armor, resistance, on-hit effects. The architecture allows these as future consumers/modifiers; they're not implemented yet.
- Healing.
- Win/loss screen.

## Verification

- The fight reaches a natural conclusion within ~10–30 seconds, not running forever.
- No unit gets "stuck" with a dead target — survivors always re-engage.
- Adding a new event consumer (e.g., a log statement) does not require modifying the damage-emitting code.

## Porting notes

- **Event-driven architecture is universal.** In Godot, this is signals. In Unity, it's UnityEvents or a custom event bus. In Bevy, it's buffered messages.
- The key property to preserve is **fan-out**: one emission can drive multiple independent reactions. Don't replace the event with a direct "deal damage to X" method call — you'll have to refactor when adding the second consumer (damage numbers, sounds, telemetry).
- **In Godot specifically**: connecting multiple receivers to a signal gives you the same shape. The combatant's `damage_dealt` signal is emitted on skill resolution, and the health node, damage-number spawner, and any future listener all connect to it.
- The "death cleanup" consumer is a common pattern: when an object is removed, anything holding a reference to it must invalidate that reference. In garbage-collected languages with weak references this is sometimes automatic, but the *explicit cleanup-on-event* pattern is more honest about what's happening.
