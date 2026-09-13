/// Records a fight as a canonical text transcript.
///
/// The transcript is the fight's observable behaviour written down: every
/// discrete decision the simulation published, in order, with the time it
/// happened. Two runs that produce the same transcript are the same fight.
///
/// This exists so a refactor can be checked against a recorded golden — see
/// `test/battle/golden_fight_test.dart`. It is deliberately plain text rather
/// than a hash: when a change is intentional the diff says what moved, and
/// when it is not, the diff says what broke.
///
/// Pure Dart, like the simulation it watches, so it runs unchanged under
/// `flutter test` and under `dart run tool/record_fight.dart`.
///
/// Continuous state is deliberately absent. Health and cooldowns are already
/// implied by the damage and heal lines, so recording the 10 Hz samples as
/// well would triple the file to say the same thing twice. The sample *count*
/// is in the summary, which is enough to pin the cadence.
library;

import 'dart:async';

import '../../../core/domain/combat_snapshot.dart';
import '../../../core/domain/faction.dart';
import '../../../core/events/game_event.dart';
import '../domain/battle_simulation.dart';

/// Numbers are recorded at fixed precision on purpose. Damage and healing are
/// whole by the time they are published, and a millisecond is finer than any
/// behavioural change worth catching — so the transcript is immune to
/// last-bit floating point drift while still failing on anything real.
String _time(double seconds) => seconds.toStringAsFixed(3).padLeft(8);

String _amount(double value) => value.toStringAsFixed(0);

/// Runs [sim] to completion, recording everything it publishes.
///
/// Subscribes before starting, so the opening target acquisitions are caught.
/// Pass [restart] to replay an already-finished fight from the top, which is
/// how the seeded-restart guarantee is tested.
///
/// The fight is driven exactly one simulation step per turn of the loop. That
/// is not a frame rate — the simulation banks partial frames and resolves the
/// same fight at any of them — it is what lets each line carry the time its
/// event actually happened at. Driving several steps between drains would
/// stamp them all with the time of the last one.
Future<String> transcribeFight(
  BattleSimulation sim, {
  String label = 'mock',
  double limit = 300,
  bool restart = false,
}) async {
  final double step = sim.maxStep;
  final StringBuffer out = StringBuffer();

  int casts = 0;
  int deaths = 0;
  int samples = 0;
  int statusesApplied = 0;
  double damageTotal = 0;
  double healingTotal = 0;

  void write(String kind, String detail) =>
      out.writeln('${_time(sim.elapsed)}  ${kind.padRight(7)} $detail');

  final StreamSubscription<GameEvent> subscription =
      sim.events.listen((GameEvent event) {
    // Exhaustive on purpose: a new GameEvent should not be able to slip into
    // the simulation without someone deciding whether it belongs in the record.
    switch (event) {
      case BattleStarted():
        write('start', '');
      case BattleEnded(:final winner):
        write('end', '${winner.label} win');
      case TargetAcquired(:final unitName, :final targetName):
        write('target', '$unitName -> $targetName');
      case SkillFired(:final sourceName, :final skillName, :final kind, :final delivery):
        casts++;
        write('cast', '$sourceName  $skillName [${kind.name}/${delivery.name}]');
      case DamageDealt(
          :final sourceName,
          :final targetName,
          :final skillName,
          :final amount,
          :final remainingHealth,
        ):
        damageTotal += amount;
        write(
          'damage',
          '$sourceName -> $targetName  $skillName  ${_amount(amount)} '
              '(${_amount(remainingHealth)} left)',
        );
      case HealApplied(
          :final sourceName,
          :final targetName,
          :final skillName,
          :final amount,
          :final remainingHealth,
        ):
        healingTotal += amount;
        write(
          'heal',
          '$sourceName -> $targetName  $skillName  +${_amount(amount)} '
              '(${_amount(remainingHealth)} left)',
        );
      case StatusApplied(
          :final sourceName,
          :final targetName,
          :final statusName,
          :final stacks,
        ):
        statusesApplied++;
        write(
          'status',
          '$sourceName -> $targetName  $statusName'
              '${stacks > 1 ? ' x$stacks' : ''}',
        );
      case StatusEnded(:final unitName, :final statusName, :final expired):
        write('status', '$unitName  $statusName ${expired ? 'ends' : 'cleansed'}');
      case UnitDied(:final unitName, :final faction):
        deaths++;
        write('death', '$unitName (${faction.name})');
      case BattleSampled():
        samples++;
      case BattlePaused():
      case BattleResumed():
      case BattleReset():
        write('lifecycle', event.runtimeType.toString());
      // Player intent never reaches the simulation's own stream; it arrives on
      // the Bloc's inbox. Recording it would mean the transcript had picked up
      // a UI dependency.
      case StartBattleRequested():
      case PauseBattleRequested():
      case ResumeBattleRequested():
      case RestartBattleRequested():
      case SpeedChangeRequested():
        break;
    }
  });

  if (restart) {
    sim.restart();
  } else {
    sim.start();
  }
  // Drain before the first step so the opening lines carry t=0 rather than the
  // timestamp of the step that happened to flush them.
  await Future<void>.delayed(Duration.zero);

  while (sim.status == BattleStatus.running && sim.elapsed < limit) {
    sim.update(step);
    // Let the broadcast stream drain so lines land in fight order, stamped
    // with the time they actually happened. One update is exactly one step, so
    // the elapsed read here is the step the event was emitted in.
    await Future<void>.delayed(Duration.zero);
  }
  await Future<void>.delayed(Duration.zero);
  await subscription.cancel();

  final BattleSnapshot end = sim.snapshot();
  final bool resolved = end.status == BattleStatus.finished;

  final StringBuffer header = StringBuffer()
    ..writeln('# guild overseer — fight transcript')
    ..writeln('# roster           $label')
    ..writeln('# seed             ${sim.seed}')
    ..writeln('# step             ${step.toStringAsFixed(6)}s')
    ..writeln('# sample interval  ${sim.sampleInterval}s')
    ..writeln('#')
    ..writeln('# Regenerate with: dart run tool/record_fight.dart')
    ..writeln('# A diff here is a change in what the simulation decides.')
    ..writeln('');

  final StringBuffer summary = StringBuffer()
    ..writeln('')
    ..writeln('--- result ---')
    ..writeln(
      resolved
          ? 'resolved  ${_time(sim.elapsed).trim()}s  winner ${end.winner!.label}'
          // Loud rather than silent: a truncated fight must not read as a pass.
          : 'UNRESOLVED after ${_time(sim.elapsed).trim()}s (limit ${limit}s)',
    )
    ..writeln(
      'casts $casts  damage ${_amount(damageTotal)}  '
      'healing ${_amount(healingTotal)}  statuses $statusesApplied  '
      'deaths $deaths  samples $samples',
    )
    ..writeln('');

  for (final Faction faction in Faction.values) {
    for (final UnitSnapshot unit in end.of(faction)) {
      summary.writeln(
        '  ${faction.name.padRight(5)} ${unit.name.padRight(18)} '
        '${_amount(unit.health).padLeft(4)}/${_amount(unit.maxHealth).padLeft(4)}'
        '${unit.isAlive ? '' : '  down'}',
      );
    }
  }

  return '$header$out$summary';
}

/// Builds a fresh simulation and records the fight it produces.
Future<String> recordFight({
  required RosterBuilder rosterBuilder,
  String label = 'mock',
  int seed = 20260912,
  double sampleInterval = 0.1,
  double limit = 300,
}) async {
  final BattleSimulation sim = BattleSimulation(
    rosterBuilder: rosterBuilder,
    seed: seed,
    sampleInterval: sampleInterval,
  );
  try {
    return await transcribeFight(sim, label: label, limit: limit);
  } finally {
    await sim.dispose();
  }
}
