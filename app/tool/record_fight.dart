// Re-records the golden fight transcript the tests compare against.
//
//   dart run tool/record_fight.dart
//
// Run this when a change to the simulation is *intended* to change the fight,
// then read the diff before committing it. The diff is the review: it says
// exactly which decisions moved. If you did not expect a diff, you have found
// the bug the golden exists to catch.
import 'dart:io';

import 'package:guild_overseer/src/features/battle/data/mock_roster.dart';
import 'package:guild_overseer/src/features/battle/debug/fight_transcript.dart';

/// Kept in step with `test/battle/golden_fight_test.dart`.
const String goldenPath = 'test/battle/goldens/mock_roster_fight.txt';

Future<void> main() async {
  final String transcript = await recordFight(
    rosterBuilder: buildMockRoster,
    label: 'mock',
  );

  final File file = File(goldenPath);
  final bool existed = file.existsSync();
  final String? before = existed ? file.readAsStringSync() : null;

  file.parent.createSync(recursive: true);
  file.writeAsStringSync(transcript);

  if (!existed) {
    stdout.writeln('created $goldenPath');
  } else if (before == transcript) {
    stdout.writeln('unchanged $goldenPath');
  } else {
    stdout.writeln('UPDATED $goldenPath — review the diff before committing');
  }
}
