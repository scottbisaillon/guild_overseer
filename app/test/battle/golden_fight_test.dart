import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:guild_overseer/src/core/domain/combat_snapshot.dart';
import 'package:guild_overseer/src/features/battle/data/mock_roster.dart';
import 'package:guild_overseer/src/features/battle/debug/fight_transcript.dart';
import 'package:guild_overseer/src/features/battle/domain/battle_simulation.dart';
import 'package:guild_overseer/src/features/battle/domain/combatant.dart';

/// The refactor safety net.
///
/// The simulation is a pure function of its roster and its seed, so the whole
/// fight can be written down and checked. Everything else in these tests is
/// about protecting that property: if the fight stops being reproducible, the
/// golden stops being evidence of anything.
///
/// When a change to the simulation is *meant* to change the fight, regenerate
/// with `dart run tool/record_fight.dart` and review the diff. When it is not
/// meant to, the diff is the bug report.
void main() {
  group('golden fight', () {
    test('the mock roster fight matches the recorded transcript', () async {
      final File golden = File('test/battle/goldens/mock_roster_fight.txt');
      expect(
        golden.existsSync(),
        isTrue,
        reason: 'Missing golden. Create it with: '
            'dart run tool/record_fight.dart',
      );

      final String actual =
          await recordFight(rosterBuilder: buildMockRoster, label: 'mock');
      final String expected = golden.readAsStringSync();

      if (actual != expected) {
        fail(_describeDrift(expected, actual));
      }
    });

    test('two fresh simulations play the same fight', () async {
      final String a = await recordFight(rosterBuilder: buildMockRoster);
      final String b = await recordFight(rosterBuilder: buildMockRoster);

      expect(a, b);
    });

    test('a restarted simulation replays the fight it just played', () async {
      final BattleSimulation sim =
          BattleSimulation(rosterBuilder: buildMockRoster);
      addTearDown(sim.dispose);

      final String first = await transcribeFight(sim);
      final String replay = await transcribeFight(sim, restart: true);

      // The replay carries one extra line — the reset itself — and is
      // otherwise the same fight, beat for beat.
      expect(_withoutLifecycle(replay), _withoutLifecycle(first));
    });

    test('the outcome does not depend on the frame rate', () {
      // The simulation banks partial frames and only ever advances in whole
      // steps, so how time is delivered cannot change what happens. Without
      // that, the fight players watch at 120Hz would not be the fight recorded
      // above — and the golden would be pinning the test harness rather than
      // the game.
      final _Outcome reference = _play(<double>[1 / 60]);

      final Map<String, List<double>> schedules = <String, List<double>>{
        '120Hz': <double>[1 / 120],
        '30Hz': <double>[1 / 30],
        '144Hz': <double>[1 / 144],
        'coarse': <double>[0.1],
        // A real frame stream: never the same twice, with a stutter in it.
        'jittery': <double>[1 / 60, 1 / 59, 1 / 62, 1 / 144, 0.25, 1 / 61],
      };

      for (final MapEntry<String, List<double>> entry in schedules.entries) {
        expect(
          _play(entry.value),
          reference,
          reason: '${entry.key} resolved a different fight from 60Hz',
        );
      }
    });

    test('speed changes the pace, not the fight', () {
      // 4x is a transport control, not a difficulty setting: it should reach
      // the same end state, having simulated the same amount of fight time.
      final _Outcome normal = _play(<double>[1 / 60]);
      final _Outcome fast = _play(<double>[1 / 60], speed: 4);

      expect(fast, normal);
    });
  });
}

/// Everything about how a fight ended, in a comparable form.
typedef _Outcome = ({String winner, String elapsed, String health});

/// Runs the mock roster to completion, feeding frames from [schedule] on
/// repeat, and reduces the result to what a fight *outcome* means.
_Outcome _play(List<double> schedule, {double speed = 1}) {
  final BattleSimulation sim = BattleSimulation(rosterBuilder: buildMockRoster);
  addTearDown(sim.dispose);
  sim.setSpeed(speed);
  sim.start();

  int frame = 0;
  while (sim.status == BattleStatus.running && sim.elapsed < 300) {
    sim.update(schedule[frame++ % schedule.length]);
  }

  return (
    winner: sim.winner?.name ?? 'none',
    elapsed: sim.elapsed.toStringAsFixed(3),
    health: sim.units
        .map((Combatant c) => '${c.id}=${c.health.toStringAsFixed(0)}')
        .join(' '),
  );
}

String _withoutLifecycle(String transcript) => transcript
    .split('\n')
    .where((String line) => !line.contains('lifecycle'))
    .join('\n');

/// A 25KB diff is unreadable in a test runner, so report where the fight first
/// diverged and how it ended differently. That pair is usually enough to name
/// the cause without opening the file.
String _describeDrift(String expected, String actual) {
  final List<String> a = expected.split('\n');
  final List<String> b = actual.split('\n');

  final StringBuffer out = StringBuffer()
    ..writeln('The fight no longer matches the recorded transcript.')
    ..writeln('')
    ..writeln('If this change was intended, re-record it and review the diff:')
    ..writeln('  dart run tool/record_fight.dart')
    ..writeln('  git diff test/battle/goldens/')
    ..writeln('');

  for (int i = 0; i < a.length && i < b.length; i++) {
    if (a[i] != b[i]) {
      out
        ..writeln('First divergence at line ${i + 1}:')
        ..writeln('  recorded: ${a[i]}')
        ..writeln('  now:      ${b[i]}')
        ..writeln('');
      break;
    }
  }
  if (a.length != b.length) {
    out.writeln('Transcript length: ${a.length} lines -> ${b.length} lines');
  }

  out
    ..writeln('Recorded outcome: ${_resultBlock(expected)}')
    ..writeln('Current outcome:  ${_resultBlock(actual)}');
  return out.toString();
}

String _resultBlock(String transcript) {
  const String marker = '--- result ---';
  final int at = transcript.indexOf(marker);
  if (at < 0) {
    return 'unknown';
  }
  return transcript
      .substring(at + marker.length)
      .trim()
      .split('\n')
      .take(2)
      .join('  ');
}
