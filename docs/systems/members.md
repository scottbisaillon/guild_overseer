# Members

Guild members are the core unit of the game. Each is an entity with stats, a class, [[traits|traits]], a [[skills|skill tree]], and six gear slots. The player character is a permanent member created at game start and cannot be dismissed.

**Depends on:** [[traits]], [[skills]], [[loot]], [[reputation]]

---

## Recruitment

Members are recruited from two sources:

- **Shared Tavern** — abstract public pool, quality gated by [[reputation|Reputation]]. Available before and after founding.
- **Guild Tavern** — private pool with better weighting, unlocked post-founding as a facility upgrade.

| Tavern | Pool Size | Quality |
|---|---|---|
| Shared | 4 | Reputation-gated common → uncommon |
| Guild Basic | 4 | Higher chance of rare trait combos |
| Guild Tier 2 | 6 | Higher chance of rare trait combos |
| Guild Legendary | 8 | Chance of unique / exotic traits |

Each recruit has a randomly generated name, class, level, trait set, and Gold hiring cost.

---

## Stats

| Stat | Range | Description |
|---|---|---|
| **Level** | 1–60 | Base stat values and dungeon eligibility |
| **Morale** | 0–100 | Affects performance. Drops on failure, rises on wins |
| **Loyalty** | 0–100 | Risk of leaving if low for too long |
| **Fatigue** | 0–100 | Increases with consecutive runs. Requires rest or consumables |
| **Experience** | — | Earned from runs. Levels up the member over time |

---

## Roles

Party compositions should meet minimum role requirements per dungeon — violations apply stacking penalties rather than blocking dispatch. See [[dungeon#Party Requirements]].

| Role | Primary Stat | Function | Synergy Traits |
|---|---|---|---|
| **Tank** | Fortitude | Absorb damage, generate threat, protect squishies | Tank Mentality, Veteran, Tryhard |
| **Healer** | Restoration | Keep party alive, remove debuffs, revive fallen members | Pacifist Healer, Completionist, Casual |
| **DPS – Melee** | Strength | High single-target damage, front-line presence | Glass Cannon, Min-Maxer, Speedrunner |
| **DPS – Ranged** | Precision | Consistent AoE and boss damage from safety | Glass Cannon, Tryhard, Min-Maxer |
| **Support** | Insight | Buffs, crowd control, trap disarm, loot detection | Completionist, Veteran, Casual |

---

## Gear Slots

Each member has six equipment slots assigned via [[../ui/loot-distribution|Loot Distribution]].

- **Weapon** — damage / healing output
- **Helm** — resilience, morale modifier
- **Chest** — defence, HP bonus
- **Gloves** — skill speed, crit chance
- **Legs** — fatigue reduction, movement
- **Trinket** — unique passive effects, trait modifiers

See [[loot]] for rarity tiers and enhancement.

---

## Implementation Notes

### Bevy

Members are ECS entities. Stats are separate `Component` structs (`Health`, `Morale`, `Fatigue`, `Loyalty`). The player character carries a zero-sized `PlayerCharacter` marker component — all other systems treat them identically to recruited members, using `With<PlayerCharacter>` / `Without<PlayerCharacter>` in queries only where the distinction is necessary.

Member spawning is a system that takes class and trait definitions from `Res<ClassData>` and `Res<TraitData>` and bundles all component structs onto a new entity via `Commands::spawn`.

### Flutter + Flame
Each member is a Dart model class (`Member`) with value semantics and a `copyWith` method. Stats are fields on the model — `health`, `morale`, `fatigue`, `loyalty`, `experience`. The player character carries an `isPlayerCharacter: bool` field.

Member state lives in `GuildCubit` as `List<Member>`. Mutations go through Cubit methods that return a new state with `copyWith`. The Flame active run layer receives member data via a `StreamController<GameEvent>` bridge — see [[combat#Flutter + Flame Notes]].

Member spawning is a pure Dart factory function that takes class and trait definitions from `DataRepository` and returns a fully initialised `Member` object.
