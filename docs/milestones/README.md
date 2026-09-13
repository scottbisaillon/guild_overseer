# Milestones

This folder captures the incremental slices that built the current combat prototype. Each file describes a milestone in **engine-agnostic terms** — what behavior the slice delivers, what design choices were made, and what's deliberately left out. The aim is that each milestone reads as a self-contained prompt you can hand to a developer (or LLM) working in any engine, including a Godot port.

## How to read these

Each file follows the same shape:

- **Goal** — the one-sentence outcome of the slice.
- **Scope** — what's included.
- **Design Decisions** — the choices made, expressed at the design level, not the implementation level. (No "use a marker component" — instead "the unit is in this state when X is true.")
- **Observable Behavior** — what you should see in the running game when the slice is done.
- **Out of Scope** — what to deliberately *not* do, so the next slice has room to land.

## The milestones in order

1. [One square on the screen](01-one-square-on-screen.md) — minimum viable scene
2. [Allies and enemies](02-allies-and-enemies.md) — two factions, visually distinct
3. [Debug inspection](03-debug-inspection.md) — on-demand state readout
4. [Targeting](04-targeting.md) — each unit finds its nearest opponent
5. [Movement](05-movement.md) — units close on their target
6. [Stop in range](06-stop-in-range.md) — units halt when within attack range
7. [Cooldown rhythm](07-cooldown-rhythm.md) — a global tick gates actions
8. [Skills](08-skills.md) — multiple skills per unit, prioritized rotation
9. [Damage and death](09-damage-and-death.md) — units take damage, die, and the fight resolves
10. [Visual feedback](10-visual-feedback.md) — health bars and floating numbers
11. [Data-driven skills](11-data-driven-skills.md) — skill definitions move to a data file
12. [Party selection screen](12-party-selection.md) — pre-gameplay UI for picking a party
13. [Customizing a unit's skills](13-skill-customization.md) — a general skill pool the player picks a rotation from

## Notes on porting

The prototype was built in Bevy (ECS, immediate-mode systems, event messages). Many design choices were shaped by ECS strengths — "state is which components are present," "events broadcast to many consumers," and so on. When translating to Godot:

- **Entities/components → nodes/scenes** with properties. Inheritance often replaces marker components.
- **Systems → per-node update methods** or autoload singletons running tick logic.
- **Events → signals.** Multiple listeners can connect to the same signal, replicating fan-out.
- **Resources → singletons or autoload nodes.**
- **State as component presence → state as a property or finite-state machine on the node.**

The *behavior* and *design decisions* in each milestone document carry across regardless of these substitutions. Use the documents as your spec; choose the idioms that match your target engine.
