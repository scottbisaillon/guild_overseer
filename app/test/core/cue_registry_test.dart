import 'package:flutter_test/flutter_test.dart';
import 'package:guild_overseer/src/core/domain/cue_registry.dart';

/// The registry is the seam that lets the renderer gain a visual without the
/// rules knowing, so what matters is that it resolves by id and that a gap in
/// it is survivable.
void main() {
  group('CueRegistry', () {
    test('plays the builder registered under an id', () {
      final List<String> played = <String>[];
      final CueRegistry<String> cues = CueRegistry<String>()
        ..register('spark', played.add);

      cues.play('spark', 'at the target');

      expect(played, <String>['at the target']);
    });

    test('a null id is the ordinary way to say nothing happens', () {
      final List<String> played = <String>[];
      final CueRegistry<String> cues = CueRegistry<String>()
        ..register('spark', played.add);

      cues.play(null, 'ignored');

      expect(played, isEmpty);
    });

    test('an unregistered id is loud in debug', () {
      // Cosmetic gaps must be findable in development...
      final CueRegistry<String> cues = CueRegistry<String>();

      expect(() => cues.play('missing', 'x'), throwsA(isA<AssertionError>()));
    });

    test('...and does nothing worse than nothing', () {
      // ...while the release behaviour, with assertions stripped, is a no-op:
      // a fight must never end because somebody mistyped a sparkle.
      final List<String> played = <String>[];
      final CueRegistry<String> cues = CueRegistry<String>()
        ..register('spark', played.add);

      try {
        cues.play('missing', 'x');
      } on AssertionError {
        // The assertion is the debug half of the contract.
      }

      expect(played, isEmpty, reason: 'nothing else was disturbed');
    });

    test('ids are unique', () {
      final CueRegistry<String> cues = CueRegistry<String>()
        ..register('spark', (_) {});

      expect(
        () => cues.register('spark', (_) {}),
        throwsA(isA<AssertionError>()),
      );
    });

    test('reports what it knows', () {
      final CueRegistry<String> cues = CueRegistry<String>()
        ..register('a', (_) {})
        ..register('b', (_) {});

      expect(cues.knows('a'), isTrue);
      expect(cues.knows('c'), isFalse);
      expect(cues.registered, unorderedEquals(<String>['a', 'b']));
    });
  });
}
