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
/// Everything that makes a unit what it is lives here. Skills are fixed for
/// now; when skill selection lands it becomes another thing the player chooses
/// on the way from a blueprint to a combatant, not a new kind of unit.
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

  /// Worn from the start. Gear reaches the unit's numbers through the stat
  /// pipeline, so equipping here is the whole of it.
  final List<ItemDefinition> gear;

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
