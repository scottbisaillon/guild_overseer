import 'package:guild_overseer/src/core/domain/combat_role.dart';
import 'package:guild_overseer/src/core/domain/faction.dart';
import 'package:guild_overseer/src/core/domain/skill_kind.dart';
import 'package:guild_overseer/src/core/domain/target_priority.dart';
import 'package:guild_overseer/src/features/battle/domain/combatant.dart';
import 'package:guild_overseer/src/features/battle/domain/skill.dart';

/// A 1s basic attack, the filler every unit falls back on.
const SkillDefinition basicAttack = SkillDefinition(
  id: 'basic',
  name: 'Basic',
  kind: SkillKind.damage,
  delivery: SkillDelivery.melee,
  targeting: SkillTargeting.opposingPriority,
  power: 10,
  cooldown: 1,
  isBasic: true,
);

/// A 2s hard hitter that sits above the basic attack in a rotation.
const SkillDefinition heavyAttack = SkillDefinition(
  id: 'heavy',
  name: 'Heavy',
  kind: SkillKind.damage,
  delivery: SkillDelivery.melee,
  targeting: SkillTargeting.opposingPriority,
  power: 40,
  cooldown: 2,
);

/// Hits everyone sharing a column with the current target.
const SkillDefinition columnAttack = SkillDefinition(
  id: 'column',
  name: 'Column',
  kind: SkillKind.damage,
  delivery: SkillDelivery.melee,
  targeting: SkillTargeting.opposingColumn,
  power: 20,
  cooldown: 3,
);

/// Only fires when somebody on the caster's side is hurt.
const SkillDefinition healSkill = SkillDefinition(
  id: 'heal',
  name: 'Heal',
  kind: SkillKind.heal,
  delivery: SkillDelivery.beam,
  targeting: SkillTargeting.lowestHealthAlly,
  power: 30,
  cooldown: 2,
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
