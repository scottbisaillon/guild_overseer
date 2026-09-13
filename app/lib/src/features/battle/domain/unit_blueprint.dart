import '../../../core/domain/combat_role.dart';
import '../../../core/domain/faction.dart';
import '../../../core/domain/item.dart';
import '../../../core/domain/target_priority.dart';
import 'combatant.dart';
import 'skill.dart';

/// A unit as authored, before it stands anywhere.
///
/// A [Combatant] is mutable and knows its slot in a formation; a blueprint is
/// neither. That split is what the party screen needs: the player picks from
/// blueprints and decides where each one stands, and only then — at the moment
/// a fight begins — does a blueprint become a combatant in a slot.
///
/// Everything that makes a unit what it is lives here, including the skills it
/// was authored with. The player may trade those out on the party screen —
/// [withSkills] hands back the same unit carrying different ones, because a
/// customised unit is a unit, not a new kind of thing.
class UnitBlueprint {
  const UnitBlueprint({
    required this.id,
    required this.name,
    required this.role,
    required this.maxHealth,
    required this.priority,
    required this.skills,
    this.gear = const <ItemDefinition>[],
  });

  /// Stable across the app: this is what a placement refers to, and what the
  /// spawned combatant is identified by in the fight.
  final String id;
  final String name;
  final CombatRole role;
  final double maxHealth;

  /// How this unit picks an opponent. A per-unit default until the rotation
  /// editor lets the player set it.
  final TargetPriority priority;

  /// Skills in rotation order: the first ready one fires.
  final List<SkillDefinition> skills;

  /// The skills the player chose, or the authored ones until they choose:
  /// everything this unit brings apart from its basic attack.
  List<SkillDefinition> get chosenSkills => <SkillDefinition>[
        for (final SkillDefinition skill in skills)
          if (!skill.isBasic) skill,
      ];

  /// The fallback this unit never gives up. A basic attack is what a unit does
  /// while its specials cool down, so it is not the player's to trade away and
  /// it always sits at the bottom of the rotation.
  List<SkillDefinition> get basicSkills => <SkillDefinition>[
        for (final SkillDefinition skill in skills)
          if (skill.isBasic) skill,
      ];

  /// Worn from the start. Gear reaches the unit's numbers through the stat
  /// pipeline, so equipping here is the whole of it.
  final List<ItemDefinition> gear;

  /// The same unit fighting with [chosen] instead of what it was authored
  /// with, its basic attack still last in the rotation.
  ///
  /// Order is priority order, so the order [chosen] arrives in is the order
  /// the player put them in.
  UnitBlueprint withSkills(List<SkillDefinition> chosen) => UnitBlueprint(
        id: id,
        name: name,
        role: role,
        maxHealth: maxHealth,
        priority: priority,
        skills: <SkillDefinition>[...chosen, ...basicSkills],
        gear: gear,
      );

  /// A fresh combatant of this unit, standing at [row]/[column].
  ///
  /// Fresh every time, because the simulation steps its units in place — two
  /// fights must never share one.
  Combatant spawn({
    required Faction faction,
    required int row,
    required int column,
  }) {
    final Combatant unit = Combatant(
      id: id,
      name: name,
      faction: faction,
      role: role,
      row: row,
      column: column,
      maxHealth: maxHealth,
      priority: priority,
      skills: skills,
    );
    for (final ItemDefinition item in gear) {
      unit.gear.equip(item);
    }
    return unit;
  }
}
