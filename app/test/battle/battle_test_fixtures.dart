import 'package:guild_overseer/src/core/domain/combat_role.dart';
import 'package:guild_overseer/src/core/domain/faction.dart';
import 'package:guild_overseer/src/core/domain/presentation.dart';
import 'package:guild_overseer/src/core/domain/target_priority.dart';
import 'package:guild_overseer/src/features/battle/domain/combatant.dart';
import 'package:guild_overseer/src/features/battle/domain/skill.dart';
import 'package:guild_overseer/src/core/domain/target_selector.dart';
import 'package:guild_overseer/src/core/domain/skill_effect.dart';

/// A 1s basic attack, the filler every unit falls back on.
const SkillDefinition basicAttack = SkillDefinition(
  id: 'basic',
  name: 'Basic',
  cooldown: 1,
  isBasic: true,
  presentation: PresentationSpec(cast: Cue.lunge),
  effects: <EffectSpec>[
    EffectSpec(
      selector: TargetSelector.currentEnemy,
      effect: DamageEffect(coefficient: 1),
    ),
  ],
);

/// A 2s hard hitter that sits above the basic attack in a rotation.
const SkillDefinition heavyAttack = SkillDefinition(
  id: 'heavy',
  name: 'Heavy',
  cooldown: 2,
  presentation: PresentationSpec(cast: Cue.lunge),
  effects: <EffectSpec>[
    EffectSpec(
      selector: TargetSelector.currentEnemy,
      effect: DamageEffect(coefficient: 4),
    ),
  ],
);

/// Hits everyone sharing a column with the current target.
const SkillDefinition columnAttack = SkillDefinition(
  id: 'column',
  name: 'Column',
  cooldown: 3,
  presentation: PresentationSpec(cast: Cue.lunge),
  effects: <EffectSpec>[
    EffectSpec(
      selector: TargetSelector.currentEnemyColumn,
      effect: DamageEffect(coefficient: 2),
    ),
  ],
);

/// Only fires when somebody on the caster's side is hurt.
const SkillDefinition healSkill = SkillDefinition(
  id: 'heal',
  name: 'Heal',
  cooldown: 2,
  presentation: PresentationSpec(travel: Cue.beam, color: CueColor.heal),
  effects: <EffectSpec>[
    EffectSpec(
      selector: TargetSelector.mostWoundedAlly,
      effect: HealEffect(coefficient: 3),
    ),
  ],
);

Combatant unit({
  required String id,
  Faction faction = Faction.ally,
  CombatRole role = CombatRole.meleeDps,
  int row = 0,
  int column = 0,
  double maxHealth = 100,
  TargetPriority priority = TargetPriority.nearest,
  List<SkillDefinition> skills = const <SkillDefinition>[basicAttack],
  double globalCooldown = 1,
}) =>
    Combatant(
      id: id,
      name: id,
      faction: faction,
      role: role,
      row: row,
      column: column,
      maxHealth: maxHealth,
      priority: priority,
      skills: skills,
      globalCooldown: globalCooldown,
    );
