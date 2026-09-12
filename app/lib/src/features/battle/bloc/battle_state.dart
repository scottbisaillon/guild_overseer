import 'package:equatable/equatable.dart';

import '../../../core/domain/combat_snapshot.dart';
import '../../../core/domain/faction.dart';

/// What a combat log line is about, which decides how it is coloured.
enum CombatLogKind { damage, heal, death, targeting, system }

/// One line in the combat log.
class CombatLogEntry extends Equatable {
  const CombatLogEntry({
    required this.text,
    required this.kind,
    required this.at,
  });

  final String text;
  final CombatLogKind kind;

  /// Seconds into the fight.
  final double at;

  @override
  List<Object?> get props => <Object?>[text, kind, at];
}

/// Everything the battle HUD renders.
class BattleState extends Equatable {
  const BattleState({
    required this.snapshot,
    required this.log,
    required this.speed,
  });

  const BattleState.initial()
      : snapshot = const BattleSnapshot.empty(),
        log = const <CombatLogEntry>[],
        speed = 1;

  final BattleSnapshot snapshot;
  final List<CombatLogEntry> log;
  final double speed;

  BattleStatus get status => snapshot.status;

  Faction? get winner => snapshot.winner;

  bool get isFinished => status == BattleStatus.finished;

  List<UnitSnapshot> unitsOf(Faction faction) => snapshot
      .of(faction)
      .toList(growable: false);

  BattleState copyWith({
    BattleSnapshot? snapshot,
    List<CombatLogEntry>? log,
    double? speed,
  }) =>
      BattleState(
        snapshot: snapshot ?? this.snapshot,
        log: log ?? this.log,
        speed: speed ?? this.speed,
      );

  @override
  List<Object?> get props => <Object?>[snapshot, log, speed];
}
