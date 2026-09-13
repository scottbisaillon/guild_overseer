import 'dart:math' as math;

import '../../../core/domain/combat_role.dart';
import '../../../core/domain/combat_snapshot.dart';
import '../../../core/domain/faction.dart';
import '../../../core/domain/stat.dart';
import '../../../core/domain/stat_block.dart';
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
    required double maxHealth,
    required this.priority,
    required List<SkillDefinition> skills,
    double globalCooldown = 1.0,
  })  : stats = StatBlock(<Stat, double>{
          Stat.maxHealth: maxHealth,
          Stat.globalCooldown: globalCooldown,
        }),
        health = maxHealth,
        _knownMaxHealth = maxHealth,
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

  /// Every number about this unit, and everything currently changing them.
  ///
  /// Gear, buffs, auras and traits all grant modifiers here rather than
  /// reaching into fields, so none of them needs to know about the others.
  /// Call [refreshStats] after changing what this block holds.
  final StatBlock stats;

  /// How this unit picks an opponent.
  final TargetPriority priority;

  /// Skills in priority order: the first ready one fires.
  final List<SkillSlot> rotation;

  double health;

  /// The max health this unit was last reconciled against, so [refreshStats]
  /// can tell how far it moved.
  double _knownMaxHealth;

  /// The unit this one is attacking, held until it becomes invalid rather than
  /// re-picked every frame.
  String? targetId;

  double _globalCooldownRemaining = 0;

  /// This unit's health ceiling, after gear and buffs.
  double get maxHealth => stats.value(Stat.maxHealth);

  /// Seconds between actions. Every unit acts on this rhythm, so a fight has a
  /// readable beat instead of a flurry of independent timers.
  double get globalCooldown => stats.value(Stat.globalCooldown);

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

  /// Reconciles the unit with its stats after modifiers were added or removed.
  ///
  /// Health is carried across as a *fraction*, so swapping a helm or losing a
  /// buff cannot heal or kill: a unit at half health stays at half health. The
  /// dead stay dead, because a fraction of zero is zero.
  void refreshStats() {
    final double next = maxHealth;
    if (next == _knownMaxHealth) {
      return;
    }
    final double fraction = _knownMaxHealth <= 0 ? 0 : health / _knownMaxHealth;
    _knownMaxHealth = next;
    health = (next * fraction).clamp(0, next);
  }

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
