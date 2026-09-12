import 'package:equatable/equatable.dart';

import 'combat_role.dart';
import 'faction.dart';
import 'target_priority.dart';

/// Lifecycle of a single battle.
enum BattleStatus { notStarted, running, paused, finished }

/// Immutable read-model of one skill's cooldown, for the HUD.
class SkillSnapshot extends Equatable {
  const SkillSnapshot({
    required this.id,
    required this.name,
    required this.cooldown,
    required this.remaining,
  });

  final String id;
  final String name;

  /// Full cooldown duration in seconds.
  final double cooldown;

  /// Seconds left before the skill can fire again.
  final double remaining;

  bool get isReady => remaining <= 0;

  /// 0.0 just after firing, 1.0 when ready again.
  double get progress =>
      cooldown <= 0 ? 1 : (1 - (remaining / cooldown)).clamp(0.0, 1.0);

  @override
  List<Object?> get props => <Object?>[id, name, cooldown, remaining];
}

/// Immutable read-model of one combatant, for the HUD.
///
/// The simulation owns mutable combatants; the UI only ever sees snapshots.
class UnitSnapshot extends Equatable {
  const UnitSnapshot({
    required this.id,
    required this.name,
    required this.faction,
    required this.role,
    required this.row,
    required this.column,
    required this.health,
    required this.maxHealth,
    required this.priority,
    required this.skills,
    this.targetId,
    this.targetName,
  });

  final String id;
  final String name;
  final Faction faction;
  final CombatRole role;

  /// Row within the unit's formation grid, top to bottom.
  final int row;

  /// Column within the formation grid: 0 is the front line, closest to the
  /// centre of the arena.
  final int column;

  final double health;
  final double maxHealth;
  final TargetPriority priority;
  final List<SkillSnapshot> skills;
  final String? targetId;
  final String? targetName;

  bool get isAlive => health > 0;

  double get healthFraction =>
      maxHealth <= 0 ? 0 : (health / maxHealth).clamp(0.0, 1.0);

  @override
  List<Object?> get props => <Object?>[
        id,
        name,
        faction,
        role,
        row,
        column,
        health,
        maxHealth,
        priority,
        skills,
        targetId,
        targetName,
      ];
}

/// Everything the HUD needs to draw one frame of the fight.
class BattleSnapshot extends Equatable {
  const BattleSnapshot({
    required this.status,
    required this.units,
    required this.elapsed,
    this.winner,
  });

  const BattleSnapshot.empty()
      : status = BattleStatus.notStarted,
        units = const <UnitSnapshot>[],
        elapsed = 0,
        winner = null;

  final BattleStatus status;
  final List<UnitSnapshot> units;

  /// Seconds of simulated combat time since the battle started.
  final double elapsed;
  final Faction? winner;

  Iterable<UnitSnapshot> of(Faction faction) =>
      units.where((UnitSnapshot u) => u.faction == faction);

  @override
  List<Object?> get props => <Object?>[status, units, elapsed, winner];
}
