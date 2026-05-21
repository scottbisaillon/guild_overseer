# Early Game — The Adventurer Phase

Before the guild exists, Guild Overseer is a solo adventurer game. This phase teaches every core system through natural play and ends with the guild founding.

**Systems introduced here:** [[systems/members]], [[systems/traits]], [[systems/skills]], [[systems/reputation]], [[systems/dungeon]]

---

## Character Creation

The player creates their character using the same systems as any guild member. Choices made here are permanent for the lifetime of the run.

- **Class** — Tank, Healer, DPS Melee, DPS Ranged, or Support. Defines the player character's role in every active run. A Tank character anchors every active run on threat; a Healer makes active runs forgiving but shifts how idle parties must be composed.
- **Starting Traits** — Two traits drawn from the class's natural pool, assigned rather than chosen. Part of the character's personality.
- **Skill Tree** — First skill points are spent immediately, introducing the [[systems/rotation|rotation system]] before the first dungeon.
- **Name** — Appears in drama events, combat logs, and trait interactions throughout the game.

---

## Early Recruitment — The Shared Tavern

Before founding a guild the player recruits from a shared public tavern — an abstract pool gated entirely by [[systems/reputation|Reputation]].

- Fixed at 4 recruits. Same refresh timer as the guild Tavern.
- Low reputation yields common-tier recruits with rough trait combinations. Better reputation surfaces better combinations, though rare combos remain unlikely until the guild Tavern is built.
- No upgrade path. Take what the pool offers or wait for a refresh.

See [[ui/tavern]].

---

## Early Dungeon Runs

Early runs use every system at lower tier and with a smaller party. The first run may be two or three members including the player character.

- **Active by default** — The player is always present early. Idle runs have no mechanical benefit before founding.
- **Reputation on clear** — Every completed run awards [[systems/reputation|Reputation]] scaled to run quality.
- **Loot** — Uses the same [[ui/loot-distribution|post-run screen]] as the full game. The player character has no special loot priority.

---

## Player Character Death

When the player character is downed mid-run and no resurrection is available, the run ends immediately. The party retreats with loot and reputation earned from completed rooms.

> [!note] Future System — Run Continuation
> A future update will offer a choice at death: end the run (current behaviour), or send the remaining party on without you at reduced odds — effectively converting the active run to idle mid-run. Deferred to keep the first version focused. See [[roadmap]].

---

## Founding the Guild

When cumulative [[systems/reputation|Reputation]] reaches the founding threshold, the player may found a guild. One-time action.

- **Cost** — A Gold payment representing the deed and charter.
- **What unlocks** — Guild Hall with a basic Tavern, the full management loop, ability to dispatch parties without the player character (idle runs).
- **The player character** — Becomes a permanent guild member. Cannot be dismissed. Class, traits, and gear carry forward.
- **The shared tavern** — Remains accessible post-founding alongside the new guild Tavern.

> [!tip] The Founding Moment
> The UI marks this with a brief ceremony. The guild name is displayed, the hall view loads for the first time, and the first event log entry reads: *[Player Name] founded [Guild Name].*

---

## Active vs Idle — The Defining Mechanic

| Mode | Condition | Resolution |
|---|---|---|
| **Active** | Player character in party | Real-time: pathfinding, auto-battle, [[systems/qte\|QTEs]] |
| **Idle** | Player character not in party | Tick-based: stat formulas, trait probability rolls |

No other distinction exists. Same dungeons, same members, same trait interactions, same loot tables. The only variable is your presence.

**Strategic implication:** The player character's class shapes which compositions work for active runs. Sending a Tank-less party into a hard dungeon is riskier idle — there is no player to respond to QTEs that might have saved a squishy member.
