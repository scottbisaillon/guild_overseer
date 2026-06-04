# Milestone 6: Stop in range

## Goal

Combatants stop moving when they're within attack range of their target. They settle into formation a short distance apart instead of overshooting and oscillating.

## Scope

- An "attack range" property on each combatant.
- A check that determines whether each combatant is currently in range of its target.
- Movement logic that only fires when a combatant has a target *and is not in range*.
- An "in range" state that future combat logic can read.

## Design Decisions

- **"In range" is a tracked state, not recomputed at every use site.** A dedicated routine maintains the state per-frame. Movement, attack execution, animations — all consult the same state. This keeps the distance check in one place.
- **Attack range is a per-unit property.** A melee unit has short range; a ranged unit has long range. This is the natural value to vary later.
- **Range comparison uses squared distance.** Compare against `range × range` to avoid the square root.
- **State updates are reactive to position changes.** As units move (toward each other in this slice, but in any direction in future slices), the in-range state updates accordingly. A unit kited out of range should transition back to "not in range" and resume moving.
- **Movement filters on "has target AND not in range."** A unit with no target doesn't move (idle). A unit in range doesn't move (engaging). Each frame the filter naturally picks up units in the right state.

## Observable Behavior

- Enter gameplay.
- Units approach each other, slow as more of them enter range, and come to rest in a loose formation a short distance apart.
- No oscillation, no pile-up at a single point.
- If you forced a unit to move (e.g., by editing its position), it would settle back into formation once in range again.

## Out of Scope

- Attack execution (next milestones).
- Maintaining a formation, facing, or other tactical behavior.
- Repositioning when a target dies (no death yet).

## Verification

Mentally identify three states a combatant might be in:
1. **Idle** — no target. Doesn't move, doesn't fight.
2. **Closing** — has target, not in range. Moves toward target.
3. **Engaging** — has target, in range. Doesn't move; fighting behavior will live here.

Each state should correspond to a checkable condition based on the unit's current data.

## Porting notes

- **In ECS engines**, these states are typically expressed as the presence or absence of marker components. Movement queries filter "has target, not in range."
- **In node-based engines**, the natural equivalent is a finite state machine or a property/enum that the per-frame update consults. The principle is the same: a single source of truth for "what state is this unit in" derived from the data on the unit, not from a separate global tracker.
- Avoid the temptation to write a hand-rolled FSM with `enter()` / `exit()` callbacks if the state can be cleanly *derived* from data. The "is in range" state is genuinely derived (it's a distance comparison), so a derived/computed property is honest.
