# Milestone 4: Targeting

## Goal

Every combatant in the scene has a current target: the nearest unit of an opposing faction. The target is a stable reference that other behaviors can read.

## Scope

- A target acquisition routine that runs per-frame (or as needed).
- A "target" property on each combatant: either a reference to another combatant, or empty.
- Logic that walks combatants without a target and assigns one.
- The debug inspection from the previous milestone now shows the assigned target per unit.

## Design Decisions

- **Target is a reference to a specific other unit.** Not "the nearest at the moment of damage" — a stored reference that persists across frames until invalidated. This makes movement, combat, and animation systems agree on who's being targeted.
- **Acquisition is "find nearest opposing combatant by world distance."** Tie-breaking can be arbitrary (first encountered wins) for now.
- **A unit acquires a target only when it has none.** Don't re-target every frame; that thrashes and creates jittery behavior. Hold the assigned target until it becomes invalid (target leaves the scene, dies, etc. — handled in later milestones).
- **Self-targeting and same-faction targeting are filtered out.** A unit can't target itself, and an ally can't target an ally.
- **Distance is computed in world space.** If units are nested under a moving parent, world position is what matters — local position can mislead.

## Observable Behavior

- Enter gameplay; press the debug-inspection key.
- Each ally has a target that is one of the enemies.
- Each enemy has a target that is one of the allies.
- The chosen target is the nearest opposing unit.

## Out of Scope

- Re-targeting when a target dies (death doesn't exist yet).
- Player-controlled targeting.
- Threat tables, taunt, or priority rules beyond "nearest."
- Range checks — a target is acquired even if the target is far away.

## Verification

If you mentally measure distances from each ally to each enemy, the assigned target is the closer one in every case.

## Porting notes

- In ECS-style engines, this is two parallel queries on the same component set with different filters (one for "needs a target," one for "all possible targets").
- In Godot or any node-based engine, this is "for every combatant, check all other combatants, find the closest opponent." Loop, check faction, compute squared distance, keep the minimum. The result is a reference (signal target / node path / weak ref).
- Use **squared distance** for comparison — square roots are unnecessary when only ordering matters.
