import 'package:equatable/equatable.dart';

import '../domain/combat_snapshot.dart';
import '../domain/faction.dart';
import '../domain/skill_kind.dart';

/// Everything that happens in the game, as data.
///
/// The simulation writes these to a broadcast stream; the Bloc consumes them
/// directly as its own events, so there is no translation layer between the
/// game loop and the UI. Later systems (traits, QTEs, loot) add their events to
/// this same hierarchy.
///
/// `sealed` keeps the set closed, so a `switch` over a `GameEvent` is checked
/// for exhaustiveness by the compiler.
sealed class GameEvent extends Equatable {
  const GameEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

// ---------------------------------------------------------------------------
// Battle lifecycle
// ---------------------------------------------------------------------------

final class BattleStarted extends GameEvent {
  const BattleStarted();
}

final class BattlePaused extends GameEvent {
  const BattlePaused();
}

final class BattleResumed extends GameEvent {
  const BattleResumed();
}

final class BattleReset extends GameEvent {
  const BattleReset();
}

final class BattleEnded extends GameEvent {
  const BattleEnded(this.winner);

  final Faction winner;

  @override
  List<Object?> get props => <Object?>[winner];
}

// ---------------------------------------------------------------------------
// Combat
// ---------------------------------------------------------------------------

final class TargetAcquired extends GameEvent {
  const TargetAcquired({
    required this.unitId,
    required this.unitName,
    required this.targetId,
    required this.targetName,
  });

  final String unitId;
  final String unitName;
  final String targetId;
  final String targetName;

  @override
  List<Object?> get props => <Object?>[unitId, unitName, targetId, targetName];
}

final class SkillFired extends GameEvent {
  const SkillFired({
    required this.sourceId,
    required this.sourceName,
    required this.targetIds,
    required this.skillId,
    required this.skillName,
    required this.kind,
    required this.delivery,
  });

  final String sourceId;
  final String sourceName;

  /// Every unit the skill resolves against. Single-target skills carry one id.
  final List<String> targetIds;
  final String skillId;
  final String skillName;
  final SkillKind kind;
  final SkillDelivery delivery;

  @override
  List<Object?> get props => <Object?>[
        sourceId,
        sourceName,
        targetIds,
        skillId,
        skillName,
        kind,
        delivery,
      ];
}

final class DamageDealt extends GameEvent {
  const DamageDealt({
    required this.sourceId,
    required this.sourceName,
    required this.targetId,
    required this.targetName,
    required this.skillName,
    required this.amount,
    required this.remainingHealth,
  });

  final String sourceId;
  final String sourceName;
  final String targetId;
  final String targetName;
  final String skillName;
  final double amount;
  final double remainingHealth;

  @override
  List<Object?> get props => <Object?>[
        sourceId,
        sourceName,
        targetId,
        targetName,
        skillName,
        amount,
        remainingHealth,
      ];
}

final class HealApplied extends GameEvent {
  const HealApplied({
    required this.sourceId,
    required this.sourceName,
    required this.targetId,
    required this.targetName,
    required this.skillName,
    required this.amount,
    required this.remainingHealth,
  });

  final String sourceId;
  final String sourceName;
  final String targetId;
  final String targetName;
  final String skillName;
  final double amount;
  final double remainingHealth;

  @override
  List<Object?> get props => <Object?>[
        sourceId,
        sourceName,
        targetId,
        targetName,
        skillName,
        amount,
        remainingHealth,
      ];
}

final class UnitDied extends GameEvent {
  const UnitDied({
    required this.unitId,
    required this.unitName,
    required this.faction,
  });

  final String unitId;
  final String unitName;
  final Faction faction;

  @override
  List<Object?> get props => <Object?>[unitId, unitName, faction];
}

// ---------------------------------------------------------------------------
// Sampling
//
// Health bars and cooldown meters are continuous state, not discrete facts, so
// they arrive on a fixed low-frequency sample rather than once per rendered
// frame. Discrete facts above drive the combat log and the arena effects.
// ---------------------------------------------------------------------------

final class BattleSampled extends GameEvent {
  const BattleSampled(this.snapshot);

  final BattleSnapshot snapshot;

  @override
  List<Object?> get props => <Object?>[snapshot];
}

// ---------------------------------------------------------------------------
// Player intent
//
// UI-originated events travel the same bus so the Bloc has a single inbox.
// ---------------------------------------------------------------------------

final class StartBattleRequested extends GameEvent {
  const StartBattleRequested();
}

final class PauseBattleRequested extends GameEvent {
  const PauseBattleRequested();
}

final class ResumeBattleRequested extends GameEvent {
  const ResumeBattleRequested();
}

final class RestartBattleRequested extends GameEvent {
  const RestartBattleRequested();
}

final class SpeedChangeRequested extends GameEvent {
  const SpeedChangeRequested(this.speed);

  final double speed;

  @override
  List<Object?> get props => <Object?>[speed];
}
