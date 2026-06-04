# Milestone 8: Skills

## Goal

Each combatant has multiple skills, each with its own cooldown and damage value. The cooldown rhythm picks one ready skill per tick, fires it, and resets its individual cooldown. Higher-priority skills fire when available; a "basic attack" fills the gaps.

## Scope

- A skill data type with: name, damage, cooldown duration.
- Each combatant carries a list of skills (ordered by priority).
- Per-skill cooldowns that tick independently and tick always (matching the GCD rule).
- Skill execution logic: when GCD is ready and the unit is engaging, walk the skill list, find the first ready skill, fire it, reset *its* cooldown and the GCD.

## Design Decisions

- **Skills are first-class data, not strings or enums on the combatant.** Each skill is its own thing the unit owns. Adding a new skill type is adding a new data entry, not editing a combat enum.
- **Skill order encodes priority.** First-ready in list order wins. To prioritize a heavy hitter, put it first; the basic attack goes last.
- **The basic attack's cooldown matches the GCD.** This guarantees something is always ready when the GCD fires — the unit never stalls with nothing to do. Specials are "above" the basic attack in priority and fire when their longer cooldowns allow.
- **Only one skill per GCD tick.** Find first ready, fire, stop. The next skill waits for the next GCD.
- **Per-skill cooldowns tick always, like the GCD.** Same reasoning — repositioning shouldn't waste cooldown progress.
- **Future-proof for player customization.** The skill list order is the player-facing knob. Eventually a player will pick the order; for now, that order is set in code or data.

## Observable Behavior

- Enter gameplay.
- A unit with both a 1s "basic attack" and a 2s "large attack" alternates predictably: large, basic, large, basic — large every 2s, basic on the off-second when large is on cooldown.
- A unit with only a basic attack fires it every 1s.
- The rotation feels rhythmic, with heavy hits at expected intervals.

## Out of Scope

- Skill effects beyond damage (heals, buffs, AoE, status).
- Cast times, channeled abilities, animations.
- Resource costs (mana, stamina).
- Skill picker UI.

## Verification

After ~10 seconds of combat, the console log shows the expected rotation pattern for each unit type. Different units with different skill lists produce visibly different attack rhythms.

## Porting notes

- **In ECS**, skills are child entities of the combatant carrying their own cooldown components.
- **In node-based engines (Godot, Unity)**, skills are child nodes (e.g., `SkillNode`) attached to the combatant scene, each with its own cooldown timer. The combatant iterates its children to find the first ready one.
- Either pattern preserves the key property: **the skill is a self-contained thing**, not a switch case inside the combatant's attack method. Adding a new skill type doesn't touch existing skills' code.
