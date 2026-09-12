# Guild Overseer — Overview

**Genre:** Idle / Active Management Sim  
**Platform:** PC · iOS · Android  
**Engine:** Bevy 0.15 · Rust · ECS

## Concept

Guild Overseer begins as a solo adventurer game and grows into a guild management simulation. The player starts as a single character — picking a class, recruiting companions from a shared tavern, and running dungeons to build reputation. When reputation reaches a threshold, the player founds a guild and the full management layer unlocks.

Every system introduced in the early game scales into the guild phase. The trait system, skill rotations, dungeon mechanics, and loot distribution all behave identically before and after founding. The guild layer is additive, not a replacement.

**The defining mechanic:** whether a dungeon run is active or idle is determined entirely by whether the player character is in the dispatched party.

## Core Fantasy

> You start as a nobody in a tavern, talking strangers into following you into a dungeon. You end as the guild leader behind the scenes — the strategist who knows which personalities clash, who to trust with the legendary sword, and how to turn a group of misfits into a legendary raiding party.

## Design Pillars

- **Personality-Driven Strategy** — [[systems/traits|Traits]] make every member feel unique and force meaningful roster decisions.
- **Earned Progression** — Every system is introduced through play. The player earns the guild by understanding it first.
- **Presence as Mechanic** — Active vs idle is not a mode setting. It is whether you show up.
- **Rewarding Progression** — [[systems/skills|Skill trees]], [[systems/traits|traits]], [[systems/reputation|reputation]], and [[systems/economy|guild upgrades]] create layered long-term goals.
- **Emergent Drama** — The clash of personalities generates stories and memorable moments without scripted events.

## Target Platforms

- **Primary:** PC (Steam)
- **Secondary:** iOS and Android
- Cross-save via cloud between platforms

## Key Documents

- [[early-game]] — The adventurer phase and guild founding
- [[gameplay-loop]] — The three interconnected loops post-guild
- [[plan]] — Vertical slice task plan
- [[roadmap]] — Release phases and future systems
- [[architecture/combat-extensibility]] — How the combat systems stay extensible
