import '../../../core/domain/combat_role.dart';
import '../../../core/domain/faction.dart';
import '../../../core/domain/presentation.dart';
import '../../../core/domain/stat.dart';
import '../../../core/domain/stat_modifier.dart';
import '../../../core/domain/status.dart';
import '../../../core/domain/target_priority.dart';
import '../domain/combatant.dart';
import '../domain/skill.dart';
import '../../../core/domain/target_selector.dart';
import '../../../core/domain/skill_effect.dart';

/// The hand-authored roster the battle mockup fights with.
///
/// This is the stand-in for data the game will eventually load: party members
/// come from the roster the player composed, enemies from the dungeon room
/// definition. Keeping it in one file means the whole mockup can be re-tuned
/// without touching combat code.

// ---------------------------------------------------------------------------
// Statuses
//
// A buff and a damage over time are the same shape — they differ only in what
// they carry. Neither needed a line of combat code to exist.
// ---------------------------------------------------------------------------

/// Physical damage over time. Ticks are resolved through the ordinary effect
/// path, so a bleed rolls, scales and kills exactly as a sword swing does.
const StatusDefinition bleeding = StatusDefinition(
  id: 'bleeding',
  name: 'Bleeding',
  duration: 6,
  tickInterval: 2,
  tags: <StatusTag>{StatusTag.debuff, StatusTag.bleed},
  maxStacks: 3,
  policy: StackPolicy.stack,
  onTick: <SkillEffect>[DamageEffect(coefficient: 1.2)],
  presentation: PresentationSpec(
    impact: Cue.debuffMark,
    color: CueColor.debuff,
  ),
);

/// The tank braces. Straight mitigation for a while, granted as a modifier
/// like anything else and removed with the status.
const StatusDefinition fortified = StatusDefinition(
  id: 'fortified',
  name: 'Fortified',
  duration: 8,
  tags: <StatusTag>{StatusTag.buff},
  modifiers: <StatModifier>[
    StatModifier.increased(
      Stat.damageTakenMultiplier,
      -0.35,
      source: ModifierSource.status('fortified'),
    ),
  ],
  presentation: PresentationSpec(impact: Cue.buffMark, color: CueColor.buff),
);

// ---------------------------------------------------------------------------
// Ally skills
// ---------------------------------------------------------------------------

const SkillDefinition shieldSlam = SkillDefinition(
  id: 'shield_slam',
  name: 'Shield Slam',
  cooldown: 6,
  presentation: PresentationSpec(cast: Cue.lunge),
  effects: <EffectSpec>[
    EffectSpec(
      selector: TargetSelector.currentEnemy,
      effect: DamageEffect(coefficient: 3),
    ),
  ],
);

const SkillDefinition fortify = SkillDefinition(
  id: 'fortify',
  name: 'Fortify',
  cooldown: 12,
  presentation: PresentationSpec(travel: Cue.beam),
  effects: <EffectSpec>[
    EffectSpec(
      selector: TargetSelector.self,
      effect: ApplyStatusEffect(fortified),
    ),
  ],
);

const SkillDefinition recklessStrike = SkillDefinition(
  id: 'reckless_strike',
  name: 'Reckless Strike',
  cooldown: 8,
  presentation: PresentationSpec(cast: Cue.lunge),
  effects: <EffectSpec>[
    EffectSpec(
      selector: TargetSelector.currentEnemy,
      effect: DamageEffect(coefficient: 6.2),
    ),
  ],
);

const SkillDefinition cleave = SkillDefinition(
  id: 'cleave',
  name: 'Cleave',
  cooldown: 5,
  presentation: PresentationSpec(cast: Cue.lunge),
  effects: <EffectSpec>[
    EffectSpec(
      selector: TargetSelector.currentEnemyColumn,
      effect: DamageEffect(coefficient: 2.2),
    ),
  ],
);

const SkillDefinition piercingShot = SkillDefinition(
  id: 'piercing_shot',
  name: 'Piercing Shot',
  cooldown: 4,
  presentation: PresentationSpec(travel: Cue.bolt),
  effects: <EffectSpec>[
    EffectSpec(
      selector: TargetSelector.currentEnemy,
      effect: DamageEffect(coefficient: 4.2),
    ),
  ],
);

const SkillDefinition mend = SkillDefinition(
  id: 'mend',
  name: 'Mend',
  cooldown: 4,
  presentation: PresentationSpec(travel: Cue.beam, color: CueColor.heal),
  effects: <EffectSpec>[
    EffectSpec(
      selector: TargetSelector.mostWoundedAlly,
      effect: HealEffect(coefficient: 5.8),
    ),
  ],
);

const SkillDefinition disrupt = SkillDefinition(
  id: 'disrupt',
  name: 'Disrupt',
  cooldown: 7,
  presentation: PresentationSpec(travel: Cue.beam),
  effects: <EffectSpec>[
    EffectSpec(
      selector: TargetSelector.currentEnemy,
      effect: DamageEffect(coefficient: 3.4),
    ),
  ],
);

const SkillDefinition strike = SkillDefinition(
  id: 'strike',
  name: 'Strike',
  cooldown: 1,
  isBasic: true,
  presentation: PresentationSpec(cast: Cue.lunge),
  effects: <EffectSpec>[
    EffectSpec(
      selector: TargetSelector.currentEnemy,
      effect: DamageEffect(coefficient: 1.4),
    ),
  ],
);

const SkillDefinition shot = SkillDefinition(
  id: 'shot',
  name: 'Shot',
  cooldown: 1,
  isBasic: true,
  presentation: PresentationSpec(travel: Cue.bolt),
  effects: <EffectSpec>[
    EffectSpec(
      selector: TargetSelector.currentEnemy,
      effect: DamageEffect(coefficient: 1.3),
    ),
  ],
);

const SkillDefinition smite = SkillDefinition(
  id: 'smite',
  name: 'Smite',
  cooldown: 1,
  isBasic: true,
  presentation: PresentationSpec(travel: Cue.beam),
  effects: <EffectSpec>[
    EffectSpec(
      selector: TargetSelector.currentEnemy,
      effect: DamageEffect(coefficient: 0.9),
    ),
  ],
);

// ---------------------------------------------------------------------------
// Enemy skills
// ---------------------------------------------------------------------------

const SkillDefinition crushingBlow = SkillDefinition(
  id: 'crushing_blow',
  name: 'Crushing Blow',
  cooldown: 6,
  presentation: PresentationSpec(cast: Cue.lunge),
  effects: <EffectSpec>[
    EffectSpec(
      selector: TargetSelector.currentEnemy,
      effect: DamageEffect(coefficient: 3.2),
    ),
  ],
);

const SkillDefinition rend = SkillDefinition(
  id: 'rend',
  name: 'Rend',
  cooldown: 5,
  presentation: PresentationSpec(cast: Cue.lunge),
  effects: <EffectSpec>[
    EffectSpec(
      selector: TargetSelector.currentEnemy,
      effect: DamageEffect(coefficient: 3.6),
    ),
    // The cut keeps bleeding. A second effect on the same target, which is
    // what the effect list was for.
    EffectSpec(
      selector: TargetSelector.currentEnemy,
      effect: ApplyStatusEffect(bleeding),
    ),
  ],
);

const SkillDefinition arcBolt = SkillDefinition(
  id: 'arc_bolt',
  name: 'Arc Bolt',
  cooldown: 4,
  presentation: PresentationSpec(travel: Cue.bolt),
  effects: <EffectSpec>[
    EffectSpec(
      selector: TargetSelector.currentEnemy,
      effect: DamageEffect(coefficient: 3.6),
    ),
  ],
);

const SkillDefinition darkMend = SkillDefinition(
  id: 'dark_mend',
  name: 'Dark Mend',
  cooldown: 5,
  presentation: PresentationSpec(travel: Cue.beam, color: CueColor.heal),
  effects: <EffectSpec>[
    EffectSpec(
      selector: TargetSelector.mostWoundedAlly,
      effect: HealEffect(coefficient: 5),
    ),
  ],
);

const SkillDefinition hex = SkillDefinition(
  id: 'hex',
  name: 'Hex',
  cooldown: 7,
  presentation: PresentationSpec(travel: Cue.beam),
  effects: <EffectSpec>[
    EffectSpec(
      selector: TargetSelector.currentEnemy,
      effect: DamageEffect(coefficient: 4),
    ),
  ],
);

const SkillDefinition claw = SkillDefinition(
  id: 'claw',
  name: 'Claw',
  cooldown: 1,
  isBasic: true,
  presentation: PresentationSpec(cast: Cue.lunge),
  effects: <EffectSpec>[
    EffectSpec(
      selector: TargetSelector.currentEnemy,
      effect: DamageEffect(coefficient: 1.5),
    ),
  ],
);

const SkillDefinition bolt = SkillDefinition(
  id: 'bolt',
  name: 'Bolt',
  cooldown: 1,
  isBasic: true,
  presentation: PresentationSpec(travel: Cue.bolt),
  effects: <EffectSpec>[
    EffectSpec(
      selector: TargetSelector.currentEnemy,
      effect: DamageEffect(coefficient: 1.2),
    ),
  ],
);

const SkillDefinition wither = SkillDefinition(
  id: 'wither',
  name: 'Wither',
  cooldown: 1,
  isBasic: true,
  presentation: PresentationSpec(travel: Cue.beam),
  effects: <EffectSpec>[
    EffectSpec(
      selector: TargetSelector.currentEnemy,
      effect: DamageEffect(coefficient: 1),
    ),
  ],
);

const SkillDefinition lash = SkillDefinition(
  id: 'lash',
  name: 'Lash',
  cooldown: 1,
  isBasic: true,
  presentation: PresentationSpec(travel: Cue.beam),
  effects: <EffectSpec>[
    EffectSpec(
      selector: TargetSelector.currentEnemy,
      effect: DamageEffect(coefficient: 1.2),
    ),
  ],
);

// ---------------------------------------------------------------------------
// Formations
//
// Column 0 is the front line, nearest the centre of the arena; column 1 is the
// back line. Both sides use the same shape, mirrored.
// ---------------------------------------------------------------------------

/// Six party members on the left and six dungeon inhabitants on the right.
List<Combatant> buildMockRoster() => <Combatant>[
      ..._allies(),
      ..._enemies(),
    ];

List<Combatant> _allies() => <Combatant>[
      Combatant(
        id: 'ally_bramm',
        name: 'Bramm Ironvow',
        faction: Faction.ally,
        role: CombatRole.tank,
        row: 0,
        column: 0,
        maxHealth: 440,
        priority: TargetPriority.nearest,
        skills: const <SkillDefinition>[fortify, shieldSlam, strike],
      ),
      Combatant(
        id: 'ally_kessa',
        name: 'Kessa Vane',
        faction: Faction.ally,
        role: CombatRole.meleeDps,
        row: 1,
        column: 0,
        maxHealth: 260,
        priority: TargetPriority.nearest,
        skills: const <SkillDefinition>[recklessStrike, cleave, strike],
      ),
      Combatant(
        id: 'ally_doren',
        name: 'Doren Hale',
        faction: Faction.ally,
        role: CombatRole.meleeDps,
        row: 2,
        column: 0,
        maxHealth: 250,
        priority: TargetPriority.frontline,
        skills: const <SkillDefinition>[cleave, strike],
      ),
      Combatant(
        id: 'ally_ysolde',
        name: 'Ysolde Marrow',
        faction: Faction.ally,
        role: CombatRole.healer,
        row: 0,
        column: 1,
        maxHealth: 200,
        priority: TargetPriority.nearest,
        skills: const <SkillDefinition>[mend, smite],
      ),
      Combatant(
        id: 'ally_fenn',
        name: 'Fenn Quill',
        faction: Faction.ally,
        role: CombatRole.rangedDps,
        row: 1,
        column: 1,
        maxHealth: 210,
        priority: TargetPriority.weakest,
        skills: const <SkillDefinition>[piercingShot, shot],
      ),
      Combatant(
        id: 'ally_mira',
        name: 'Mira Sol',
        faction: Faction.ally,
        role: CombatRole.support,
        row: 2,
        column: 1,
        maxHealth: 220,
        priority: TargetPriority.backline,
        skills: const <SkillDefinition>[disrupt, smite],
      ),
    ];

List<Combatant> _enemies() => <Combatant>[
      Combatant(
        id: 'enemy_warden',
        name: 'Bone Warden',
        faction: Faction.enemy,
        role: CombatRole.tank,
        row: 0,
        column: 0,
        maxHealth: 470,
        priority: TargetPriority.nearest,
        skills: const <SkillDefinition>[crushingBlow, claw],
      ),
      Combatant(
        id: 'enemy_ghoul_a',
        name: 'Crypt Ghoul',
        faction: Faction.enemy,
        role: CombatRole.meleeDps,
        row: 1,
        column: 0,
        maxHealth: 265,
        priority: TargetPriority.nearest,
        skills: const <SkillDefinition>[rend, claw],
      ),
      Combatant(
        id: 'enemy_ghoul_b',
        name: 'Grave Ghoul',
        faction: Faction.enemy,
        role: CombatRole.meleeDps,
        row: 2,
        column: 0,
        maxHealth: 265,
        priority: TargetPriority.nearest,
        skills: const <SkillDefinition>[rend, claw],
      ),
      Combatant(
        id: 'enemy_acolyte',
        name: 'Plague Acolyte',
        faction: Faction.enemy,
        role: CombatRole.healer,
        row: 0,
        column: 1,
        maxHealth: 200,
        priority: TargetPriority.nearest,
        skills: const <SkillDefinition>[darkMend, wither],
      ),
      Combatant(
        id: 'enemy_construct',
        name: 'Ranged Construct',
        faction: Faction.enemy,
        role: CombatRole.rangedDps,
        row: 1,
        column: 1,
        maxHealth: 265,
        priority: TargetPriority.weakest,
        skills: const <SkillDefinition>[arcBolt, bolt],
      ),
      Combatant(
        id: 'enemy_hexweaver',
        name: 'Hexweaver',
        faction: Faction.enemy,
        role: CombatRole.support,
        row: 2,
        column: 1,
        // The Debuffer archetype hunts the party healer specifically.
        priority: TargetPriority.healerFirst,
        maxHealth: 215,
        skills: const <SkillDefinition>[hex, lash],
      ),
    ];
