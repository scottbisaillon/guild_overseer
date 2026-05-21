# Economy & Progression

**Depends on:** [[loot]], [[members]], [[reputation]]

---

## Currencies

| Currency | Source | Uses |
|---|---|---|
| **Gold** | Dungeon loot, vendor sells | Recruit costs, upgrades, consumables, guild founding cost |
| **Crystals** | Milestone rewards, premium | Cosmetics, time skips, special recruits |
| **Reputation** | Dungeon clears | Tier unlocks, NPC contracts — see [[reputation]] |
| **Essence** | Disenchanting gear | Gear enchanting, trait modification, partial respec |
| **Prestige Tokens** | Late-game content | Prestige gear crafting, guild hall unlocks |

---

## Guild Hall Upgrades

| Facility | Effect |
|---|---|
| **Tavern** | Recruit quality and pool size. Guild-private pool separates from the shared tavern. |
| **Armory** | Gear storage capacity and enhancement slots |
| **Training Grounds** | Member XP gain rate and trait improvement speed. Enables Full Respec at Tier 2+. |
| **War Room** | Unlocks multi-party dispatches and dungeon planning tools |
| **Infirmary** | Reduces injury recovery time; chance to prevent fatigue on failed runs |
| **Trophy Hall** | Displays boss trophies; passive morale bonus to all members |

---

## Monetisation Philosophy

- One-time purchase on PC; free-to-play with premium pass on mobile.
- Crystals available for cosmetics and convenience only — no stat advantage.
- No pay-to-win. All power comes from gameplay.
- Season Pass — cosmetic rewards and bonus narrative events only.

---

## Implementation Notes

### Bevy

All currencies are fields on a single `Res<Currencies>` resource that derives `Reflect` for automatic save serialisation. Guild Hall state lives in a `Res<GuildHall>` resource with per-facility tier fields.

Facility upgrade costs and unlock requirements are defined in `upgrades.ron`. The upgrade system validates against `Res<Currencies>` and `Res<GuildHall>` before applying — no hardcoded costs in systems.

### Flutter + Flame
Currencies are fields on `EconomyCubit` state — `gold`, `crystals`, `essence`, `reputationTokens`. All are `double` or `int`. Guild Hall facility levels are fields on `GuildHallCubit` state.

Facility upgrade costs and unlock requirements come from `upgrades.json` in `DataRepository`. The upgrade action validates against `EconomyCubit` state before calling `GuildHallCubit.upgrade(facility)`. All Cubit methods return new state via `copyWith` — no mutation in place.

Hive persists both Cubits' state via `SaveManager`, which is the only class that calls Hive APIs directly.
