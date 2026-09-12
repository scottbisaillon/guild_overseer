import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/events/game_event.dart';
import '../domain/battle_simulation.dart';
import 'battle_state.dart';

/// Turns the simulation's event stream into HUD state.
///
/// The Bloc's event type is [GameEvent] itself: what the simulation publishes
/// is already the vocabulary the UI cares about, so there is no translation
/// layer. Player intent (start, pause, speed) travels the same bus and is the
/// only thing that reaches back into the simulation.
class BattleBloc extends Bloc<GameEvent, BattleState> {
  BattleBloc({required this.simulation, this.onRosterRebuilt})
      : super(const BattleState.initial()) {
    // Continuous state.
    on<BattleSampled>(
      (BattleSampled event, Emitter<BattleState> emit) =>
          emit(state.copyWith(snapshot: event.snapshot)),
    );

    // Discrete facts, which become log lines.
    on<DamageDealt>(_onDamageDealt);
    on<HealApplied>(_onHealApplied);
    on<UnitDied>(_onUnitDied);
    on<TargetAcquired>(_onTargetAcquired);
    on<SkillFired>((SkillFired event, Emitter<BattleState> emit) {
      // The damage and healing lines carry the skill name already; logging the
      // cast as well would double every entry.
    });

    // Lifecycle.
    on<BattleStarted>(
      (BattleStarted event, Emitter<BattleState> emit) =>
          emit(_log('Battle begins', CombatLogKind.system)),
    );
    on<BattlePaused>(
      (BattlePaused event, Emitter<BattleState> emit) =>
          emit(_log('Paused', CombatLogKind.system)),
    );
    on<BattleResumed>(
      (BattleResumed event, Emitter<BattleState> emit) =>
          emit(_log('Resumed', CombatLogKind.system)),
    );
    on<BattleReset>(
      (BattleReset event, Emitter<BattleState> emit) => emit(
        state.copyWith(log: const <CombatLogEntry>[]),
      ),
    );
    on<BattleEnded>(
      (BattleEnded event, Emitter<BattleState> emit) => emit(
        _log('${event.winner.label} win', CombatLogKind.system),
      ),
    );

    // Player intent.
    on<StartBattleRequested>(
      (StartBattleRequested event, Emitter<BattleState> emit) =>
          simulation.start(),
    );
    on<PauseBattleRequested>(
      (PauseBattleRequested event, Emitter<BattleState> emit) =>
          simulation.pause(),
    );
    on<ResumeBattleRequested>(
      (ResumeBattleRequested event, Emitter<BattleState> emit) =>
          simulation.resume(),
    );
    on<RestartBattleRequested>(_onRestartRequested);
    on<SpeedChangeRequested>((
      SpeedChangeRequested event,
      Emitter<BattleState> emit,
    ) {
      simulation.setSpeed(event.speed);
      emit(state.copyWith(speed: simulation.speed));
    });

    _subscription = simulation.events.listen(add);
  }

  /// The fight this Bloc reports on, and the only thing it talks back to.
  final BattleSimulation simulation;

  /// Lets the renderer rebuild its components after the roster is replaced.
  final Future<void> Function()? onRosterRebuilt;

  late final StreamSubscription<GameEvent> _subscription;

  /// Newest lines are kept; the fight can run long enough to grow this without
  /// a cap.
  static const int _maxLogEntries = 120;

  void _onDamageDealt(DamageDealt event, Emitter<BattleState> emit) {
    emit(_log(
      '${event.sourceName} -> ${event.targetName}  '
      '${event.skillName} ${event.amount.toStringAsFixed(0)}',
      CombatLogKind.damage,
    ));
  }

  void _onHealApplied(HealApplied event, Emitter<BattleState> emit) {
    emit(_log(
      '${event.sourceName} -> ${event.targetName}  '
      '${event.skillName} +${event.amount.toStringAsFixed(0)}',
      CombatLogKind.heal,
    ));
  }

  void _onUnitDied(UnitDied event, Emitter<BattleState> emit) {
    emit(_log('${event.unitName} falls', CombatLogKind.death));
  }

  void _onTargetAcquired(TargetAcquired event, Emitter<BattleState> emit) {
    emit(_log(
      '${event.unitName} targets ${event.targetName}',
      CombatLogKind.targeting,
    ));
  }

  Future<void> _onRestartRequested(
    RestartBattleRequested event,
    Emitter<BattleState> emit,
  ) async {
    simulation.restart();
    await onRosterRebuilt?.call();
  }

  BattleState _log(String text, CombatLogKind kind) {
    final List<CombatLogEntry> log = <CombatLogEntry>[
      ...state.log,
      CombatLogEntry(text: text, kind: kind, at: state.snapshot.elapsed),
    ];
    return state.copyWith(
      log: log.length > _maxLogEntries
          ? log.sublist(log.length - _maxLogEntries)
          : log,
    );
  }

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
