# Milestone 7: Cooldown rhythm

## Goal

Each combatant has a "global cooldown" (GCD) — a tick that gates how often it can act. Out of range, the cooldown still progresses (so a unit isn't punished for repositioning). In range, when the cooldown expires and an action is available, the action fires and the cooldown resets.

## Scope

- A per-unit global cooldown timer.
- Per-frame logic that advances the timer regardless of state.
- Logic that consumes the timer (resetting it) only when an action actually fires.
- For this slice, "action fires" can be a console log line saying "Unit X attacked Unit Y" — the actual damage doesn't exist yet.

## Design Decisions

- **The cooldown ticks always, not only in range.** Travel time between targets shouldn't waste cooldown progress. A unit running to its next victim arrives ready to fight if the cooldown finished mid-travel.
- **The cooldown is "ready to fire" or "ticking down."** Use a one-shot timer that sits at "finished" until manually reset, not a repeating timer that auto-resets. This means a unit that finishes its cooldown out of range *stays* ready until it engages.
- **The cooldown resets only on actual action.** If a unit is in range and ready but somehow can't act (e.g., no available skills), the cooldown stays ready — it doesn't silently consume itself.
- **Starting state matters.** A unit's cooldown starts "ready" so the first action on engagement happens immediately, not after a delay. (You can change this later — the starting state is a design knob, not a constraint.)

## Observable Behavior

- Enter gameplay.
- Once units converge into range, the console begins printing "X attacked Y" lines at a steady rhythm (e.g., once per second per attacker).
- Faster units (higher movement speed) reach engagement first and start firing first.
- The log rhythm is consistent: every unit fires at the same interval once engaged.

## Out of Scope

- Skill choice (one generic action for now).
- Damage application (next milestones).
- Animation, sound, screen feedback.
- Differing cooldown rates per unit.

## Verification

If you toggle a unit out of range mid-fight (move its target away briefly), the cooldown continues to tick. When it re-engages, it fires immediately if its cooldown was full.

## Porting notes

- The "tick always, fire only when in range and ready" pattern is engine-agnostic. A timer node in Godot, a property on a Bevy component, a private float on a Unity MonoBehaviour — all express the same idea.
- The critical design choice — "the cooldown ticks regardless of state" — is one of the load-bearing intuitions of the combat feel. Don't pause the timer when out of range; you'll have to undo it later when players complain about repositioning feeling sluggish.
