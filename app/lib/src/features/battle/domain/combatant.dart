import 'dart:math' as math;

import '../../../core/domain/combat_role.dart';
import '../../../core/domain/combat_snapshot.dart';
import '../../../core/domain/faction.dart';
import '../../../core/domain/target_priority.dart';
import 'arena_layout.dart';
import 'skill.dart';

/// A unit that fights.
///
/// Mutable by design: the simulation owns these and steps them in place. The UI
/// never sees a `Combatant`, only the [UnitSnapshot] it produces.
class Combatant {
  Combatant({
    required this.id,
    required this.name,
    required this.faction,
    required this.role,
    required this.row,
    required this.column,
    required this.maxHealth,
    required this.priority,
    required List<SkillDefinition> skills,
    this.globalCooldown = 1.0,
  })  : health = maxHealth,
        rotation = skills.map(SkillSlot.new).toList(growable: false);

  final String id;
  final String name;

  /// Which side this unit fights for. A value, not a type — a unit could change
  /// sides mid-fight by reassigning it.
  final Faction faction;
  final CombatRole role;

  /// Slot in the formation grid.
  final int row;
  final int column;

  final double maxHealth;

  /// How this unit picks an opponent.
  final TargetPriority priority;

  /// Skills in priority order: the first ready one fires.
  final List<SkillSlot> rotation;

  /// Seconds between actions. Every unit acts on this rhythm, so a fight has a
  /// readable beat instead of a flurry of independent timers.
  final double globalCooldown;

  double health;

  /// The unit this one is attacking, held until it becomes invalid rather than
  /// re-picked every frame.
  String? targetId;

  double _globalCooldownRemaining = 0;

  bool get isAlive => health > 0;

  double get healthFraction =>
      maxHealth <= 0 ? 0 : (health / maxHealth).clamp(0.0, 1.0);

  bool get isWounded => health < maxHealth;

  bool get canAct => _globalCooldownRemaining <= 0;

  double get globalCooldownRemaining => _globalCooldownRemaining;

  /// Where this unit stands, in arena space.
  ArenaPoint position(ArenaLayout layout) =>
      layout.slotCentre(faction, row, column);

  /// Advance the global cooldown and every skill cooldown. Always runs, for
  /// every living unit, whether or not it has a target.
  void tickCooldowns(double dt) {
    if (_globalCooldownRemaining > 0) {
      _globalCooldownRemaining = math.max(0, _globalCooldownRemaining - dt);
    }
    for (final SkillSlot slot in rotation) {
      slot.tick(dt);
    }
  }

  /// Called when a skill fires: the unit is busy until the next beat.
  void startGlobalCooldown() => _globalCooldownRemaining = globalCooldown;

  /// Returns the damage actually taken, which is capped by remaining health.
  double applyDamage(double amount) {
    final double taken = math.min(amount, health);
    health = math.max(0, health - amount);
    return taken;
  }

  /// Returns the healing actually applied, which is capped by missing health.
  double applyHeal(double amount) {
    final double healed = math.min(amount, maxHealth - health);
    health = math.min(maxHealth, health + amount);
    return healed;
  }

  UnitSnapshot toSnapshot({String? targetName}) => UnitSnapshot(
        id: id,
        name: name,
        faction: faction,
        role: role,
        row: row,
        column: column,
        health: health,
        maxHealth: maxHealth,
        priority: priority,
        targetId: targetId,
        targetName: targetName,
        skills: <SkillSnapshot>[
          for (final SkillSlot slot in rotation)
            SkillSnapshot(
              id: slot.definition.id,
              name: slot.definition.name,
              cooldown: slot.definition.cooldown,
              remaining: slot.remaining,
            ),
        ],
      );
}
