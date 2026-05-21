# Gameplay Loop — Post-Guild

Once the guild is founded the game operates across three interconnected loops.

**Depends on:** [[systems/dungeon]], [[systems/traits]], [[systems/loot]], [[systems/economy]], [[systems/reputation]]

---

## Daily Management Loop

1. Check guild member statuses — morale, fatigue, cooldowns. See [[systems/members]].
2. Review available dungeon contracts. See [[systems/dungeon]].
3. Compose and dispatch parties via [[ui/party-composer]].
4. Distribute loot from returned parties via [[ui/loot-distribution]].
5. Handle drama events and member complaints. See [[systems/traits#Interactions]].
6. Spend resources on upgrades, recruitment, or gear enhancement. See [[systems/economy]].

---

## Dungeon Loop

Each run progresses through a sequence of rooms ending with a boss.

- **Active run** — Real-time combat. Player manages targeting and responds to QTEs. See [[systems/combat]], [[systems/qte]].
- **Idle run** — Tick-based auto-resolution. Trait events fire probabilistically. See [[systems/dungeon]].
- Party composition and trait interactions modify outcomes at every room.
- Failure results in a wipe — members return with injuries and morale penalties.

---

## Long-Term Growth Loop

- Expand the Guild Hall with new facilities. See [[systems/economy#Guild Hall Upgrades]].
- Unlock higher-tier dungeons via [[systems/reputation|Reputation]] milestones.
- Recruit rarer members with better [[systems/traits|traits]].
- Craft Prestige gear for guild-wide passive bonuses. See [[systems/loot#Gear Enhancement]].

---

## Active vs Idle

Post-guild the player can bench themselves for any run — dispatching a party without themselves to run idle while managing other guild business. Multiple parties can clear dungeons in parallel. The player dips into active runs selectively.

See [[early-game#Active vs Idle — The Defining Mechanic]] for the full definition.
