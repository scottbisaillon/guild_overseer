// Runs the battle mockup headlessly and prints the combat log.
//
//   dart run tool/simulate_battle.dart
//
// The simulation has no Flame or Flutter dependency, so the same fight the game
// renders can be replayed in a terminal — useful for tuning numbers without
// waiting on a window to open.
import 'dart:io';

import 'package:guild_overseer/src/core/domain/combat_snapshot.dart';
import 'package:guild_overseer/src/core/events/game_event.dart';
import 'package:guild_overseer/src/features/battle/data/mock_roster.dart';
import 'package:guild_overseer/src/features/battle/domain/battle_simulation.dart';

Future<void> main(List<String> args) async {
  final bool verbose = args.contains('--verbose');
  final BattleSimulation sim = BattleSimulation(rosterBuilder: buildMockRoster);

  sim.events.listen((GameEvent event) {
    final String line = switch (event) {
      BattleStarted() => 'battle start',
      BattleEnded(:final winner) => 'battle end — ${winner.label} win',
      UnitDied(:final unitName) => '$unitName dies',
      DamageDealt(
        :final sourceName,
        :final targetName,
        :final skillName,
        :final amount,
        :final remainingHealth,
      ) =>
        verbose
            ? '$sourceName → $targetName  $skillName '
                '${amount.toStringAsFixed(0)} (${remainingHealth.toStringAsFixed(0)} left)'
            : '',
      HealApplied(:final sourceName, :final targetName, :final amount) =>
        verbose
            ? '$sourceName heals $targetName ${amount.toStringAsFixed(0)}'
            : '',
      _ => '',
    };
    if (line.isNotEmpty) {
      stdout.writeln('[${sim.elapsed.toStringAsFixed(1)}s] $line');
    }
  });

  sim.start();
  const double dt = 1 / 60;
  while (sim.status == BattleStatus.running && sim.elapsed < 300) {
    sim.update(dt);
    // Let the broadcast stream drain so the log prints in fight order, with
    // the elapsed time the events actually happened at.
    await Future<void>.delayed(Duration.zero);
  }
  await Future<void>.delayed(Duration.zero);

  stdout.writeln('');
  stdout.writeln('resolved in ${sim.elapsed.toStringAsFixed(1)}s');
  for (final UnitSnapshot unit in sim.snapshot().units) {
    stdout.writeln(
      '  ${unit.faction.name.padRight(5)} ${unit.name.padRight(18)} '
      '${unit.health.toStringAsFixed(0).padLeft(4)} / ${unit.maxHealth.toStringAsFixed(0)}',
    );
  }
  await sim.dispose();
}
