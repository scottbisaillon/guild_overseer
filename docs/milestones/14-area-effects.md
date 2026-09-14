# Milestone 14: Area attacks read as one blow

## Goal

A skill that catches several units at once looks like one blow covering ground, not like several separate hits that happened to land together — both when it lands in the fight and when it is being chosen on the party screen.

## Scope

- An **area cue** in the presentation vocabulary: a cue played once per skill, over everything it landed on, alongside the existing per-target cast/travel/impact cues.
- Two styles to author with: a **sweep** that wipes along the footprint's long axis, and a **pulse** that lights the whole footprint at once and spreads.
- The skill pool gains the shapes there were none of: a **row** attack and an attack on the **whole opposing side**, so all three shapes — rank, row, everything — exist to be seen.
- A **reach preview** in the skill picker: the arena in miniature beside every skill, with the cells that skill lands on lit up, so the shape is visible while choosing rather than only after dispatching.

## Design Decisions

- **The renderer is handed cells, not a shape.** The area cue receives the cell each target is standing in and draws the ground they add up to. A rank comes out tall and a row comes out wide because that is where those units are standing — the renderer never learns which `TargetShape` the skill used, and a shape nobody has authored yet draws correctly the day it exists.
- **Authored, not inferred from the number of targets.** A skill whose effects point at different sides — damage the enemy, buff the caster — lands on several units without covering any ground between them. Drawing a footprint across both sides of the arena for those would be worse than drawing nothing, so content says when a skill covers ground.
- **The footprint is padded, and includes the gaps between cells.** It is the ground the blow swept, not an outline traced around the units. Each cell is also outlined inside it, so the footprint says *who* was caught as well as *how much ground*.
- **Under the units, over the floor.** A wash that hides the health bars is a worse read than no wash at all.
- **The sweep runs away from the caster.** Direction is taken from where the caster stands relative to the footprint, so the blow visibly travels through the rank rather than appearing over it.
- **Bright on arrival, fading gently.** The fade is squared so the first frames hold near full strength: at 4x speed a linear fade is gone before the eye finds it.
- **A missing footprint is never fatal.** An area cue with no placeable targets draws nothing, in keeping with the rule that presentation never stops a fight.
- **The preview asks the resolver rather than reading the selector.** Where a skill lands is worked out by standing two reference formations up — everybody wounded, the caster in the middle of its own front line, locked onto the enemy opposite — and running the real targeting resolver over them. A preview that interpreted targeting for itself would be a second set of rules to keep in step with the first; this one cannot drift, and a targeting shape nobody has authored yet previews correctly the day it exists.
- **Everyone in the reference formation is wounded.** Otherwise a heal, which only selects the hurt, would preview as landing on nobody. The preview is the skill's reach when everything it wants is there — not a promise about one fight, where half the rank may already be dead.
- **The preview and the footprint agree by construction**, and a test holds them to it: a skill that reaches more than one cell is a skill that declares an area cue.

## Observable Behavior

- A Cleave through the enemy front rank draws a tall footprint over that rank, wiped through from the caster's end, with each caught unit outlined.
- A Volley draws a wide footprint over the target's row — the target and whoever stands behind it.
- A Tempest lights the whole enemy side at once and spreads outward as it fades.
- A Rally does the same over the party, in the heal colour.
- Single-target skills are unchanged: no footprint, because they cover no ground.
- In the skill picker, every skill carries a small arena — allies left, enemies right, each side's front line nearest the middle — with the cells it lands on filled: one cell for a strike, a tall block for Cleave, a wide one for Volley, a whole side for Tempest, the caster's own cell for Fortify.

## Out of Scope

- Telegraphing an area attack *before* it lands (a wind-up, a warning footprint).
- Showing reach anywhere but the picker — the bench cards still list skills by name alone.
- Per-shape art: rank, row and side all use the same two styles, distinguished only by the ground they cover.
- Sound.

## Verification

- The footprint of a rank is taller than it is wide; the footprint of a row is wider than it is tall; the footprint of a whole side contains every cell of that side and none of the other. All three are checked against the arena layout without a running game.
- The preview resolves to the shapes it claims: a rank skill covers the target's whole rank, a row skill the target and whoever stands behind it, a storm every enemy cell and no friendly one, a self buff the caster's cell alone.
- Content is checked too: a skill whose targeting can reach several units at once must name an area cue, every skill that covers several cells is one that draws a footprint, and every cue any skill names must be one the renderer registers.

## Porting notes

- **The cue is a component with a lifetime**, spawned by the renderer when the simulation publishes a skill firing. In Godot this is a `Node2D` with a `Tween` or an `AnimationPlayer`, freed when it finishes; in Bevy an entity with a timer component.
- **The input is a list of rects in arena space.** Whatever engine draws it, the maths is the same: the union of the cells, padded, then a wipe along its longer axis. Keeping that a pure function of the cells is what makes it testable with no engine at all.
- **Z-order matters more than the effect does.** Whatever the engine calls it, the footprint belongs between the floor and the units.
- **The preview needs no engine at all.** It is the targeting resolver run against two formations of stand-in units, which is portable wherever the resolver is; only the few pixels it paints are engine work.
