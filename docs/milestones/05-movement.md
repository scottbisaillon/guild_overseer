# Milestone 5: Movement

## Goal

Every combatant with a target moves toward that target each frame. Units close on each other and converge into a clump in the middle of the field. They don't stop — that's the next milestone.

## Scope

- A movement routine that runs each frame for every combatant that has a target.
- Each unit's movement speed is a property (different units can move at different speeds).
- Movement is frame-rate independent.

## Design Decisions

- **Speed is a per-unit property.** Allies and enemies can have different speeds; future unit variety (light scouts, heavy tanks) extends naturally.
- **Movement is "step toward target by `speed × delta`."** Compute the direction vector to the target, normalize it, multiply by speed × frame delta, add to position.
- **Direction is computed safely.** If a unit happens to be exactly on top of its target, normalizing a zero vector produces NaN/garbage. Use a safe normalize that returns zero in that case.
- **Position math uses world coordinates.** Same reasoning as targeting: nested parents would otherwise produce incorrect movement.
- **No collision, no obstacle avoidance.** Units glide through each other and through any terrain. That's fine for this slice.

## Observable Behavior

- Enter gameplay.
- All four units immediately begin sliding toward their targets.
- They converge in the middle of the field.
- Without stopping logic, they overshoot and oscillate around each other indefinitely. This is expected — the next milestone fixes it.

## Out of Scope

- Stopping when in range (next milestone).
- Pathfinding, obstacle avoidance, collision.
- Animation (just position changes).
- Rotation or facing direction.
- Acceleration / deceleration / momentum — instant speed is fine.

## Verification

If you give enemies a noticeably higher speed than allies, the enemies visibly move faster across the field. The unit-speed property is doing real work.

## Porting notes

- This is the first milestone with **mutable state per frame**. In ECS engines this is a system with mutable access to position; in node-based engines it's `_process(delta)` on the combatant node.
- **Use `delta_time` (or its engine equivalent) consistently** — multiplying speed by delta is the difference between "moves at the correct speed regardless of framerate" and "moves at light speed on a fast computer."
