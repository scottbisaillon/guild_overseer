import '../../../core/domain/combat_role.dart';
import '../../../core/domain/faction.dart';
import '../../../core/domain/item.dart';
import '../../../core/domain/presentation.dart';
import '../../../core/domain/stat.dart';
import '../../../core/domain/stat_modifier.dart';
import '../../../core/domain/status.dart';
import '../../../core/domain/target_priority.dart';
import '../domain/combatant.dart';
import '../domain/party_formation.dart';
import '../domain/party_skills.dart';
import '../domain/skill.dart';
import '../domain/unit_blueprint.dart';
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
  presentation: PresentationSpec(cast: Cue.lunge, area: Cue.areaSweep),
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

/// A cut that keeps bleeding. The party's side of the status system: the same
/// [bleeding] the crypt ghouls apply, in a skill the player can hand out.
const SkillDefinition lacerate = SkillDefinition(
  id: 'lacerate',
  name: 'Lacerate',
  cooldown: 9,
  presentation: PresentationSpec(cast: Cue.lunge),
  effects: <EffectSpec>[
    EffectSpec(
      selector: TargetSelector.currentEnemy,
      effect: DamageEffect(coefficient: 2.4),
    ),
    EffectSpec(
      selector: TargetSelector.currentEnemy,
      effect: ApplyStatusEffect(bleeding),
    ),
  ],
);

/// A small heal on everybody who needs one. Weaker per head than [mend] and
/// slower, so taking both is a decision rather than an upgrade.
const SkillDefinition rally = SkillDefinition(
  id: 'rally',
  name: 'Rally',
  cooldown: 14,
  presentation: PresentationSpec(
    travel: Cue.beam,
    area: Cue.areaPulse,
    color: CueColor.heal,
  ),
  effects: <EffectSpec>[
    EffectSpec(
      selector: TargetSelector(
        side: TargetSide.allies,
        count: TargetSelector.unlimited,
        filters: <TargetFilter>[WoundedFilter()],
        includeSelf: true,
        tieBreakByDistance: false,
      ),
      effect: HealEffect(coefficient: 2.4),
    ),
  ],
);

/// Arrows over a whole row: the target and whoever is standing behind it.
///
/// The row to Cleave's rank. Both are one blow across several units, and the
/// only difference in how they read is which way the footprint runs.
const SkillDefinition volley = SkillDefinition(
  id: 'volley',
  name: 'Volley',
  cooldown: 7,
  presentation: PresentationSpec(travel: Cue.bolt, area: Cue.areaSweep),
  effects: <EffectSpec>[
    EffectSpec(
      selector: TargetSelector.currentEnemyRow,
      effect: DamageEffect(coefficient: 2.6),
    ),
  ],
);

/// Everything on the other side at once, on a cooldown long enough that it is
/// an opening rather than a rotation.
const SkillDefinition tempest = SkillDefinition(
  id: 'tempest',
  name: 'Tempest',
  cooldown: 16,
  // The caster's own colour, like every other blow: red on red enemy cells is
  // a footprint nobody can see.
  presentation: PresentationSpec(area: Cue.areaPulse),
  effects: <EffectSpec>[
    EffectSpec(
      selector: TargetSelector.allEnemies,
      effect: DamageEffect(coefficient: 1.9),
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
// The skill pool
//
// What the player may give a unit on the party screen. One pool for everybody,
// so a tank taking Mend is allowed — the shape a skill tree per class will
// eventually narrow, and the least interesting thing to get right first.
//
// Basic attacks are not in it. A unit keeps its own, because a rotation that
// can empty itself is a unit standing still.
// ---------------------------------------------------------------------------

/// Every skill a unit may be given, in the order the picker lists them.
const List<SkillDefinition> kSkillPool = <SkillDefinition>[
  shieldSlam,
  fortify,
  recklessStrike,
  cleave,
  volley,
  lacerate,
  piercingShot,
  tempest,
  disrupt,
  mend,
  rally,
];

/// The pool skill with this id, or null if there is no such skill.
SkillDefinition? poolSkill(String id) {
  for (final SkillDefinition skill in kSkillPool) {
    if (skill.id == id) {
      return skill;
    }
  }
  return null;
}

/// [unit] carrying the skills the player picked for it.
///
/// A unit nobody customised is handed back untouched, so an empty selection is
/// the authored roster — the screen opens on one, and a link that carries no
/// skills fights the fight it always did. Ids naming nothing in the pool are
/// dropped like a stale unit id in a formation: a smaller rotation beats a
/// crash, and the basic attack means it is never an empty one.
UnitBlueprint unitWithSkills(UnitBlueprint unit, PartySkills skills) {
  final List<String>? chosen = skills.forUnit(unit.id);
  if (chosen == null) {
    return unit;
  }
  return unit.withSkills(<SkillDefinition>[
    for (final String id in chosen)
      if (poolSkill(id) case final SkillDefinition skill) skill,
  ]);
}

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

// ---------------------------------------------------------------------------
// Gear
//
// An item states what it changes and nothing else. Because damage is a
// coefficient on a stat, a sword granting attack power makes every skill that
// scales off it hit harder — no skill was edited to make that true.
//
// The numbers are arbitrary, like everything else in the mockup. They read
// large because the base stats are small: +2 attack power against a base of 10
// is a fifth of a unit's output. Real content wants a higher base so a common
// weapon is a nudge rather than a transformation.
// ---------------------------------------------------------------------------

const ItemDefinition ironGreatsword = ItemDefinition(
  id: 'iron_greatsword',
  name: 'Iron Greatsword',
  slot: GearSlot.weapon,
  modifiers: <StatModifier>[
    StatModifier.flat(Stat.attackPower, 2, source: _item),
  ],
);

const ItemDefinition wardensShield = ItemDefinition(
  id: 'wardens_shield',
  name: "Warden's Shield",
  slot: GearSlot.chest,
  modifiers: <StatModifier>[
    StatModifier.flat(Stat.maxHealth, 40, source: _item),
    StatModifier.increased(Stat.damageTakenMultiplier, -0.1, source: _item),
  ],
);

const ItemDefinition huntingBow = ItemDefinition(
  id: 'hunting_bow',
  name: 'Hunting Bow',
  slot: GearSlot.weapon,
  modifiers: <StatModifier>[
    StatModifier.flat(Stat.attackPower, 2, source: _item),
  ],
);

const ItemDefinition acolytesFocus = ItemDefinition(
  id: 'acolytes_focus',
  name: "Acolyte's Focus",
  slot: GearSlot.weapon,
  modifiers: <StatModifier>[
    StatModifier.flat(Stat.healPower, 2, source: _item),
  ],
);

/// Authored modifiers are rebound to the slot they are worn in, so the source
/// they are written against never matters.
const ModifierSource _item = ModifierSource.item('authored');

// ---------------------------------------------------------------------------
// Units
//
// The cast, as blueprints rather than combatants. A blueprint does not know
// where it stands — the player decides that on the party screen, and a
// blueprint becomes a unit in a slot only when a fight is built from one. The
// dungeon's inhabitants are authored exactly the same way; they simply never
// get a say in where they stand.
// ---------------------------------------------------------------------------

/// Everybody the player may take along.
///
/// Deliberately wider than a party: six slots out of eleven candidates is what
/// makes composing one a decision. Two of each role, give or take, so no party
/// is forced and no role is unavailable.
const List<UnitBlueprint> kRecruitableUnits = <UnitBlueprint>[
  UnitBlueprint(
    id: 'ally_bramm',
    name: 'Bramm Ironvow',
    role: CombatRole.tank,
    maxHealth: 440,
    priority: TargetPriority.nearest,
    skills: <SkillDefinition>[fortify, shieldSlam, strike],
    gear: <ItemDefinition>[ironGreatsword, wardensShield],
  ),
  UnitBlueprint(
    id: 'ally_kessa',
    name: 'Kessa Vane',
    role: CombatRole.meleeDps,
    maxHealth: 260,
    priority: TargetPriority.nearest,
    skills: <SkillDefinition>[recklessStrike, cleave, strike],
    gear: <ItemDefinition>[ironGreatsword],
  ),
  UnitBlueprint(
    id: 'ally_doren',
    name: 'Doren Hale',
    role: CombatRole.meleeDps,
    maxHealth: 250,
    priority: TargetPriority.frontline,
    skills: <SkillDefinition>[cleave, strike],
  ),
  UnitBlueprint(
    id: 'ally_ysolde',
    name: 'Ysolde Marrow',
    role: CombatRole.healer,
    maxHealth: 200,
    priority: TargetPriority.nearest,
    skills: <SkillDefinition>[mend, smite],
    gear: <ItemDefinition>[acolytesFocus],
  ),
  UnitBlueprint(
    id: 'ally_fenn',
    name: 'Fenn Quill',
    role: CombatRole.rangedDps,
    maxHealth: 210,
    priority: TargetPriority.weakest,
    skills: <SkillDefinition>[piercingShot, shot],
    gear: <ItemDefinition>[huntingBow],
  ),
  UnitBlueprint(
    id: 'ally_mira',
    name: 'Mira Sol',
    role: CombatRole.support,
    maxHealth: 220,
    priority: TargetPriority.backline,
    skills: <SkillDefinition>[disrupt, smite],
  ),
  UnitBlueprint(
    id: 'ally_tovin',
    name: 'Tovin Marsh',
    role: CombatRole.tank,
    maxHealth: 400,
    priority: TargetPriority.frontline,
    skills: <SkillDefinition>[fortify, strike],
    gear: <ItemDefinition>[wardensShield],
  ),
  UnitBlueprint(
    id: 'ally_kell',
    name: 'Kell Brant',
    role: CombatRole.meleeDps,
    maxHealth: 240,
    priority: TargetPriority.weakest,
    skills: <SkillDefinition>[recklessStrike, strike],
    gear: <ItemDefinition>[ironGreatsword],
  ),
  UnitBlueprint(
    id: 'ally_serah',
    name: 'Serah Dunn',
    role: CombatRole.rangedDps,
    maxHealth: 205,
    priority: TargetPriority.backline,
    skills: <SkillDefinition>[piercingShot, shot],
    gear: <ItemDefinition>[huntingBow],
  ),
  UnitBlueprint(
    id: 'ally_orin',
    name: 'Orin Vale',
    role: CombatRole.healer,
    maxHealth: 195,
    priority: TargetPriority.nearest,
    skills: <SkillDefinition>[mend, smite],
  ),
  UnitBlueprint(
    id: 'ally_pell',
    name: 'Pell Ashgrove',
    role: CombatRole.support,
    maxHealth: 215,
    priority: TargetPriority.healerFirst,
    skills: <SkillDefinition>[disrupt, smite],
  ),
];

/// The room the mockup fights: six inhabitants, in a formation nobody picks.
const List<UnitBlueprint> kDungeonUnits = <UnitBlueprint>[
  UnitBlueprint(
    id: 'enemy_warden',
    name: 'Bone Warden',
    role: CombatRole.tank,
    maxHealth: 470,
    priority: TargetPriority.nearest,
    skills: <SkillDefinition>[crushingBlow, claw],
  ),
  UnitBlueprint(
    id: 'enemy_ghoul_a',
    name: 'Crypt Ghoul',
    role: CombatRole.meleeDps,
    maxHealth: 265,
    priority: TargetPriority.nearest,
    skills: <SkillDefinition>[rend, claw],
  ),
  UnitBlueprint(
    id: 'enemy_ghoul_b',
    name: 'Grave Ghoul',
    role: CombatRole.meleeDps,
    maxHealth: 265,
    priority: TargetPriority.nearest,
    skills: <SkillDefinition>[rend, claw],
  ),
  UnitBlueprint(
    id: 'enemy_acolyte',
    name: 'Plague Acolyte',
    role: CombatRole.healer,
    maxHealth: 200,
    priority: TargetPriority.nearest,
    skills: <SkillDefinition>[darkMend, wither],
  ),
  UnitBlueprint(
    id: 'enemy_construct',
    name: 'Ranged Construct',
    role: CombatRole.rangedDps,
    maxHealth: 265,
    priority: TargetPriority.weakest,
    skills: <SkillDefinition>[arcBolt, bolt],
  ),
  UnitBlueprint(
    id: 'enemy_hexweaver',
    name: 'Hexweaver',
    role: CombatRole.support,
    maxHealth: 215,
    // The Debuffer archetype hunts the party healer specifically.
    priority: TargetPriority.healerFirst,
    skills: <SkillDefinition>[hex, lash],
  ),
];

// ---------------------------------------------------------------------------
// Formations
//
// Column 0 is the front line, nearest the centre of the arena; column 1 is the
// back line. Both sides use the same shape, mirrored.
// ---------------------------------------------------------------------------

/// Where the party stands when the player has not composed one: the six the
/// mockup shipped with, in the slots they were authored in.
final PartyFormation kDefaultParty = PartyFormation(<FormationSlot, String>{
  (row: 0, column: 0): 'ally_bramm',
  (row: 1, column: 0): 'ally_kessa',
  (row: 2, column: 0): 'ally_doren',
  (row: 0, column: 1): 'ally_ysolde',
  (row: 1, column: 1): 'ally_fenn',
  (row: 2, column: 1): 'ally_mira',
});

/// Where the dungeon's inhabitants stand. Not the player's business.
final PartyFormation kDungeonFormation =
    PartyFormation(<FormationSlot, String>{
  (row: 0, column: 0): 'enemy_warden',
  (row: 1, column: 0): 'enemy_ghoul_a',
  (row: 2, column: 0): 'enemy_ghoul_b',
  (row: 0, column: 1): 'enemy_acolyte',
  (row: 1, column: 1): 'enemy_construct',
  (row: 2, column: 1): 'enemy_hexweaver',
});

/// The recruitable unit with this id, or null if there is no such unit.
UnitBlueprint? recruitableUnit(String id) {
  for (final UnitBlueprint unit in kRecruitableUnits) {
    if (unit.id == id) {
      return unit;
    }
  }
  return null;
}

/// The default fight: the authored party against the authored room.
///
/// The golden transcript is recorded from this, so what it builds is fixed.
List<Combatant> buildMockRoster() => buildRoster(party: kDefaultParty);

/// The party the player composed, with the skills they chose, against the room.
///
/// Placements naming a unit that does not exist are dropped rather than
/// refused — a stale link is worth a smaller party, not a crash. A party that
/// ends up empty is nobody's idea of a fight, so it falls back to the authored
/// one; the party screen will not dispatch an empty party in the first place.
List<Combatant> buildRoster({
  required PartyFormation party,
  PartySkills skills = const PartySkills.empty(),
}) {
  final List<Combatant> allies = _spawn(
    party,
    kRecruitableUnits,
    Faction.ally,
    skills,
  );
  return <Combatant>[
    ...allies.isEmpty
        ? _spawn(kDefaultParty, kRecruitableUnits, Faction.ally, skills)
        : allies,
    ..._spawn(kDungeonFormation, kDungeonUnits, Faction.enemy),
  ];
}

/// Stands [formation] up as combatants, front line first, top to bottom.
///
/// Order matters: the simulation steps units in the order it is handed them,
/// so a formation always spawning in the same order is what makes the same
/// party fight the same fight twice.
List<Combatant> _spawn(
  PartyFormation formation,
  List<UnitBlueprint> catalogue,
  Faction faction, [
  PartySkills skills = const PartySkills.empty(),
]) =>
    <Combatant>[
      for (final FormationSlot slot in PartyFormation.slots())
        if (formation.at(slot) case final String id)
          if (_find(catalogue, id) case final UnitBlueprint blueprint)
            unitWithSkills(blueprint, skills).spawn(
              faction: faction,
              row: slot.row,
              column: slot.column,
            ),
    ];

UnitBlueprint? _find(List<UnitBlueprint> catalogue, String id) {
  for (final UnitBlueprint blueprint in catalogue) {
    if (blueprint.id == id) {
      return blueprint;
    }
  }
  return null;
}
