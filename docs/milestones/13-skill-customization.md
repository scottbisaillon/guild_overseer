# Milestone 13: Customizing a unit's skills

## Goal

On the party selection screen, the player chooses which skills each unit fights with, drawn from one general pool shared by every unit. The choice travels with the party into the fight, so two parties of the same six units can fight differently.

## Scope

- A **skill pool**: a flat list of the skills a unit may be given, separate from the units themselves.
- A **skill picker** opened from a unit on the party screen — the unit's rotation in priority order above, the pool below.
- A per-unit **rotation cap** (three), and reordering, because rotation order is priority order.
- A **selection value** — unit id to chosen skill ids — held beside the formation, carried in the same link, and applied when the party is stood up as combatants.
- A **default**: a unit nobody has customised fights with the skills it was authored with, and can be reset back to them.

## Design Decisions

- **One pool for everybody, for now.** Any unit may take any skill in the pool, including one no unit was authored with. Class skill trees are what will eventually narrow that down; gating before the tree exists would be a rule with nothing behind it, and the pool is the interim shape the tree can replace without touching the screen.
- **The choice is an override, not a requirement.** A unit with no entry in the selection uses its authored skills. That keeps an untouched party identical to the authored roster — the golden fight still records the same fight — and means the screen can open empty without every unit starting blank.
- **Choosing nothing is a choice.** An empty rotation is legal and distinct from having made no choice. It is a unit that only ever uses its basic attack: weak, not broken.
- **Basic attacks are not in the pool.** Each unit keeps the basic attack it was authored with, and it always sits last in the rotation. A rotation that can empty itself is a unit standing still while its specials cool down, and the fallback is exactly what the basic attack was for. Last in the rotation is where it fires, but the picker shows it first, in a slot of its own above the rotation: it is the floor under the player's priorities, not the least of them.
- **Order is part of the choice.** The fight fires the first ready skill in rotation order, so the order the player puts skills in *is* the unit's priorities. The picker reorders rather than sorting for them.
- **The rules live with the value, not the screen.** No duplicates and no more than the cap are enforced by the selection type itself, so the screen, a decoded link and a test all get the same answer, and a hand-edited link cannot produce a rotation the game could not have built.
- **Unknown skill ids are dropped, not refused.** The same leniency a formation gives a unit id it does not recognise: a stale link is worth a shorter rotation, not a crash. The basic attack means the result is never an empty one.
- **Skills travel in the link beside the party.** Who went and what they brought are one composition, so a shared or reloaded link reproduces the same fight. Only the units actually being dispatched carry their choices along.
- **The picker lives on the party screen, not on a screen of its own.** What a unit brings is part of deciding whether to take it. A dedicated skill editor is worth the trip once there is a tree, points and a rotation score to show; a list of nine skills is not.

## Observable Behavior

- Open party select. Each unit shows the skills it is bringing.
- Open a unit's skill picker. Its basic attack has the first slot, in a section of its own, marked as the fallback it fires when everything else is on cooldown; the rotation follows below it, listed in priority order and numbered.
- Tap a pool skill to take it; tap it again to give it back. The counter reads `n/3` and the pool stops accepting once the rotation is full.
- Reorder the rotation, and the numbering follows.
- Reset a unit and it goes back to the skills it was authored with.
- Dispatch, and the fight plays out with the chosen rotations — a tank given a heal heals, and a unit whose big hit was moved to the top leads with it.
- The dispatch link carries both the formation and the skills; reloading it reproduces the same party with the same rotations.

## Out of Scope

- Skill trees, skill points, unlock requirements, and respec costs.
- Passive, Reactive, Aura and Finisher skills — everything in the pool is an Active that occupies a rotation slot.
- Per-unit target priority, which is still authored.
- A rotation quality score, trait conflicts, or any other advice about the rotation being built.
- Saving a loadout between sessions, or naming and reusing one.

## Verification

- Two parties of the same units with different rotations produce visibly different fights.
- A unit nobody customised fights exactly as it did before this slice — the recorded golden fight is unchanged.
- A link with a skill id that does not exist still loads, with that skill missing from the unit's rotation.
- A unit stripped of every chosen skill still acts, using only its basic attack.

## Porting notes

- **The selection is a plain value** — a map of unit id to an ordered list of skill ids — and belongs wherever the party selection already lives: a singleton, an autoload, or a resource. It is not per-entity state; there are no entities at selection time.
- **Applying the choice belongs in the same place the party is materialized.** The function that turns a member template into a combatant takes the chosen skill ids and looks them up in the skills manifest, exactly as it already does for the template's authored ids. Nothing downstream of it learns that the player chose anything.
- **The picker is a list over a list.** Immediate-mode (egui) rebuilds both each frame; retained-mode (Godot `ItemList`/`Control`) rebuilds them on change. The gestures are add, remove, and move one row — drag-to-reorder is the polish, not the mechanism.
