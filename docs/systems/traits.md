# Traits

Traits are the personality and behavioural characteristics of each guild member. They affect dungeon performance, loot interactions, party morale, targeting behaviour, and social dynamics. Managing trait conflicts and synergies is the central strategic layer of the game.

**Depends on:** [[members]], [[rotation]], [[combat]], [[qte]], [[loot]]

---

## Trait Schema

Each trait is defined in `traits.ron`. Key fields:

- `intensity` (0.0–1.0) — scales all effect magnitudes and probability rolls. Softening a trait reduces intensity rather than removing it entirely.
- `effects[]` — stat modifiers with scope (self / party) and optional conditions.
- `triggers[]` — event → response mappings. When a named game event fires, the trait evaluates its conditions and emits a response.
- `interactions` — `conflicts[]`, `synergies[]`, `suppresses[]` listing other trait IDs.
- `modification` — whether the trait can soften or reinforce, and via which methods.

---

## Trait Catalogue

| Trait | Type | Effect Summary |
|---|---|---|
| **Loot Goblin** | Negative | Rolls on all drops regardless of class. Personal loot +30%, party morale penalty. |
| **Tank Mentality** | Positive | Extra threat. Party damage taken −10%. Auto-intercepts Targeted Strike QTEs aimed at adjacent allies. |
| **Speedrunner** | Neutral | Dungeon time −20%, loot found −15%. Refuses last 1–2 skills in a full rotation. Always targets weakest enemy. |
| **Pacifist Healer** | Positive | Revive cooldown halved. Breaks rotation to emergency-heal any ally below 20% HP from a QTE hit. |
| **Drama Queen** | Negative | Morale hit if not given preferred role. Rage on QTE failure: +20% damage, ignores movement commands 15s. Blames nearby members for their QTE failures. |
| **Veteran** | Positive | Bonus XP to new recruits in same party. Background coaching raises lower-RQS members over time. QTE prompts appear earlier in previously-cleared dungeons. |
| **Glass Cannon** | Neutral | Damage +40%, damage taken +60%. Targets the enemy furthest from the Tank. One missed AoE frequently fatal. |
| **Tryhard** | Positive | Idle efficiency +25%. Reacts strongly to both poor and excellent RQS and QTE performance. Locks onto highest-threat enemy. |
| **AFK Prone** | Negative | Stops seeking at random intervals. Does not move to safe zone during AFK windows. |
| **Completionist** | Positive | Finds hidden loot rooms. Flags combined Trap + Telegraph rooms earlier. |
| **Min-Maxer** | Positive | Refuses suboptimal builds. Queues a drama event if 3+ QTEs missed in one room. Party optimisation bonus when all RQS is high. |
| **Casual** | Neutral | Morale buff to party, slight performance penalty. No morale penalty for QTE failures. Rarely changes target once locked. |

---

## Interactions

### Conflicts
Pairs that generate negative emergent events when in the same party:
- **Loot Goblin + Drama Queen** — 65% chance of `loot_argument` drama event mid-run, stalling progress.
- **AFK Prone + Tryhard** — AFK windows trigger Tryhard frustration events.

### Synergies
Pairs that produce bonus effects:
- **Veteran + Completionist** — No chest ever missed.
- **Tank Mentality + Veteran** — Reduced party damage in rooms the Veteran has cleared before.

### Suppression
- **Min-Maxer suppresses Loot Goblin** — Overrides 70% of goblin rolls via mechanical loot prioritisation.

---

## Targeting Overrides

Several traits override the member's configured [[combat#Target Priority|target priority]]. These cannot be suppressed by the player — they are expressions of personality.

| Trait | Override |
|---|---|
| Loot Goblin | Biases toward elite / boss-tagged enemies (most likely to drop loot) |
| Speedrunner | Always targets weakest enemy regardless of setting |
| Tryhard | Locks onto highest-threat enemy, rarely switches |
| Glass Cannon | Biases toward the enemy furthest from the Tank |
| Veteran | May break target to intercept an add threatening the Healer |
| Casual | Picks a target at room start and rarely changes it |
| AFK Prone | Sets velocity to zero during AFK windows |

---

## RQS Reactions

Traits react to [[rotation#RQS|Rotation Quality Score]] after each run. Key reactions:

- **Tryhard** below RQS 60 — morale penalty; Build Review event after two consecutive poor runs.
- **Min-Maxer** with any party member below RQS 50 — refuses to re-queue with that member until rotation is fixed.
- **Speedrunner** with a 6-slot rotation — truncates last 1–2 skills; build 4–5 slot rotations for Speedrunners.

Full table in [[rotation#Trait Reactions to RQS]].

---

## QTE Reactions

Traits react to QTE outcomes during active runs. Key reactions:

- **Tank Mentality** — auto-intercepts Targeted Strike QTEs aimed at adjacent allies.
- **Drama Queen** — Rage mode on own QTE failure; Blame Event on any nearby member's failure.
- **Glass Cannon** — 60% additional damage from any QTE miss.
- **Veteran** — QTE prompts appear earlier in previously-cleared dungeons.

Full table in [[qte#Trait Reactions]].

---

## Trait Modification

- **Mentorship** — Pairing a Veteran with a younger member reduces negative trait intensity over multiple runs. Rate defined in `traits.ron`, not hardcoded.
- **Therapy Events** — Special guild events offer trait adjustment for Essence.
- **Gear Perks** — Rare+ items may include trait suppression effects.
- **Story Events** — Narrative quests tied to specific members may permanently change their traits.

---

## Implementation Notes

### Bevy

Each member entity carries a `TraitSet` component containing a list of trait IDs. Trait definitions live in `Res<TraitData>` loaded from `traits.ron`.

Trait evaluation is split across two systems to keep query sets clean. The first reads `GameEvent`s, evaluates trait conditions from `TraitData`, and emits `TraitTriggered` events. The second reads `TraitTriggered` and applies mutations to member components — morale change, fatigue spike, velocity override, or a `DramaEventQueued` event for the UI layer.

Targeting bias is returned as a sealed enum (`BiasWeakest`, `BiasElite`, `BiasLockOn`, `BiasNone`) by a pure function called inside the targeting system. See [[combat#Bevy Notes]].

### Flutter + Flame
Trait definitions are Dart model classes (`TraitDefinition`) with `fromJson` factories, loaded from `traits.json` by `DataRepository`. The `TraitEngine` is a pure Dart class injected into `GuildCubit` — it takes a `List<Member>` and a `GameEvent` and returns a `List<TraitResponse>`.

`GameBloc` is the only Bloc — it receives `GameEvent` sealed class instances from the Flame `StreamController` and from Cubit-emitted events. The `TraitEngine.evaluate()` call lives inside `GameBloc` event handlers. Responses are applied to member models and emitted as new `CombatState`.

Targeting bias is a sealed class (`TargetBias`) returned by a pure function called inside the Flame `targeting_system` component update. See [[combat#Flutter + Flame Notes]].
