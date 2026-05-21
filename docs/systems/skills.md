# Skills & Skill Trees

Each member has a class-specific skill tree divided into three branches. Skill Points are earned at each level-up (one per level, 60 maximum). The tree defines what skills are available; the [[rotation|rotation system]] defines the order they fire.

**Depends on:** [[members]], [[rotation]]

---

## Tree Structure

| Branch | Requirement | Focus |
|---|---|---|
| **Core** | None — available from level 1 | Role-defining fundamentals. Every class's primary skills live here. |
| **Specialist** | 10 points in Core | Role enhancements and combo enablers. Unlocks mid-tier power and Reactive skills. |
| **Capstone** | 20 points in Specialist | Identity-defining abilities. Transformative effects and the class Finisher. |

---

## Skill Types

| Type | Trigger | Notes |
|---|---|---|
| **Active** | Rotation slot | Fire on cooldown in rotation order. Occupy a rotation slot. |
| **Passive** | Always on | Permanent stat modifiers or conditional bonuses. Never slotted. |
| **Reactive** | Condition-based | Auto-trigger on specific events: ally below 30% HP, enemy debuff applied, Trap Room entered. Never slotted. |
| **Finisher** | Combo requirement | Unlocks after a specific prior-skill sequence fires correctly in rotation order. |
| **Aura** | Party-wide passive | Persistent buff to nearby party members. One Aura active per member. Never slotted. |

Active skills occupy [[rotation|rotation slots]]. Passive, Reactive, and Aura skills are always live and appear in a separate always-active panel in the [[../ui/skill-editor|Skill Editor]].

---

## Example Skill Trees

### Tank

| Skill | Branch | Type | Effect |
|---|---|---|---|
| Shield Slam | Core | Active | High threat generation. 6s cooldown. |
| Fortify | Core | Passive | +15% physical damage reduction permanently. |
| Taunt | Core | Active | Forces all enemies to target this member for 4s. 12s cooldown. |
| Iron Wall | Specialist | Reactive | Auto-triggers 3s damage-immunity shield when HP drops below 25%. |
| Guardian Aura | Specialist | Aura | Adjacent party members take 8% less damage. |
| Last Stand | Capstone | Finisher | After Taunt → Shield Slam fires in sequence: all enemies stunned 3s, Tank regains 20% HP. |

### Healer

| Skill | Branch | Type | Effect |
|---|---|---|---|
| Mend | Core | Active | Heals the lowest-HP ally. 4s cooldown. |
| Purify | Core | Reactive | Auto-cleanses a debuff within 1s of application. |
| Renew | Core | Active | Heal-over-time on target for 8s. 10s cooldown. |
| Revive | Specialist | Active | Revives a downed member at 40% HP. 60s cooldown. |
| Serenity Aura | Specialist | Aura | Party regenerates 2% HP every 5s out of active combat. |
| Miracle | Capstone | Finisher | After Mend → Renew → Purify in sequence: full party healed to 80% HP, all debuffs cleansed. |

### DPS (Melee)

| Skill | Branch | Type | Effect |
|---|---|---|---|
| Cleave | Core | Active | Hits all enemies in front. 5s cooldown. |
| Reckless Strike | Core | Active | High single-target damage; user takes 10% back. 8s cooldown. |
| Battle Frenzy | Core | Passive | +8% attack speed permanently. |
| Execute | Specialist | Reactive | Auto-triggers an additional strike when an enemy falls below 15% HP. |
| War Cry | Specialist | Aura | Party melee damage +10% for the combat room. |
| Death Spiral | Capstone | Finisher | After Cleave → Reckless Strike → Cleave: AoE burst for 300% weapon damage. |

### Support

| Skill | Branch | Type | Effect |
|---|---|---|---|
| Empower | Core | Active | Buffs one ally's next skill +30% effectiveness. 8s cooldown. |
| Disrupt | Core | Active | Interrupts an enemy ability cast. 10s cooldown. |
| Detect Trap | Core | Reactive | Auto-disarms Trap Rooms, preventing party damage. |
| Rouse | Specialist | Active | Removes 20 Fatigue from one ally. 30s cooldown. |
| Tactician Aura | Specialist | Aura | All party cooldowns reduced by 10%. |
| Perfect Synergy | Capstone | Finisher | After Empower → Disrupt → Rouse: all party cooldowns fully reset. |

---

## Respeccing

| Method | Cost | Scope |
|---|---|---|
| Partial Respec | 15 Essence per point | Refund individual nodes. Available anywhere. |
| Full Respec | 200 Essence | Returns all points. Requires Training Grounds Tier 2+. |
| Prestige Respec | Free + 1 Prestige Point | On Prestige reset. Prestige Point unlocks a fourth post-Prestige branch. |
| Mentorship Bonus | — | Veteran paired with a lower-level member grants +1 Skill Point every 5 runs. |

---

## Implementation Notes

### Bevy

The skill tree state per member is a component holding a map of invested points per skill ID and the available unspent points. Skill definitions are static data in `Res<SkillData>` loaded from `skills.ron`.

Finisher detection uses a sliding window of recently-fired skills stored in the rotation component. On each skill fire the window is checked against the finisher's required sequence from `SkillData`. No hardcoded sequences — everything is data-driven.

Respec operations modify the skill tree component and deduct from `Res<Currencies>`. The Training Grounds requirement is checked against `Res<GuildHall>` tier before allowing a full respec.

### Flutter + Flame
Skill definitions are Dart model classes (`SkillDefinition`) with `fromJson` factories. The skill tree state per member is a field on the `Member` model: a map of invested points per skill ID and available unspent points.

The `SkillTree` widget in [[../ui/skill-editor#Flutter + Flame Notes]] is a `CustomPainter` — edges drawn as `Path` objects, nodes as `Rect` with `GestureDetector` overlays. Finisher sequence detection is a pure Dart function on the `SkillRotation` model, called in the Flame component update loop.

Respec operations call `GuildCubit` methods that update the member model and deduct from `EconomyCubit`.
