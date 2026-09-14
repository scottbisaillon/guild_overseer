import 'package:flutter_test/flutter_test.dart';
import 'package:guild_overseer/src/core/domain/rng.dart';

/// Determinism is the feature, so these are the properties an idle run's
/// reproducibility actually rests on — not that the numbers are any good.
void main() {
  group('GameRandom', () {
    test('the same seed draws the same sequence', () {
      List<int> draw(int seed) {
        final GameRandom random = GameRandom(seed);
        return <int>[for (int i = 0; i < 20; i++) random.nextInt(1000)];
      }

      expect(draw(7), draw(7));
    });

    test('different seeds draw different sequences', () {
      final GameRandom a = GameRandom(7);
      final GameRandom b = GameRandom(8);

      expect(
        <int>[for (int i = 0; i < 20; i++) a.nextInt(1000)],
        isNot(<int>[for (int i = 0; i < 20; i++) b.nextInt(1000)]),
      );
    });

    test('restart replays what it just drew', () {
      final GameRandom random = GameRandom(31);
      final List<int> first = <int>[
        for (int i = 0; i < 10; i++) random.nextInt(1000),
      ];

      random.restart();

      expect(<int>[for (int i = 0; i < 10; i++) random.nextInt(1000)], first);
    });

    test('a named stream is the same generator every time it is forked', () {
      final GameRandom run = GameRandom(2026);

      expect(run.fork('loot').seed, run.fork('loot').seed);
    });

    test('different names fork to different generators', () {
      final GameRandom run = GameRandom(2026);

      expect(run.fork('loot').seed, isNot(run.fork('traits').seed));
    });

    // The property the whole design is for: a system that starts drawing must
    // not move any other system's sequence. Drawing a hundred numbers from the
    // loot stream leaves the trait stream exactly where it was.
    test('drawing from one stream does not disturb another', () {
      final GameRandom run = GameRandom(2026);
      final GameRandom traitsBefore = run.fork('traits');
      final List<int> expected = <int>[
        for (int i = 0; i < 10; i++) traitsBefore.nextInt(1000),
      ];

      final GameRandom loot = run.fork('loot');
      for (int i = 0; i < 100; i++) {
        loot.nextInt(1000);
      }
      final GameRandom traitsAfter = run.fork('traits');

      expect(
        <int>[for (int i = 0; i < 10; i++) traitsAfter.nextInt(1000)],
        expected,
      );
    });

    test('a stream forked off a stream is still deterministic', () {
      int roomLoot(int seed, int room) =>
          GameRandom(seed).fork('room:$room').fork('loot').nextInt(10000);

      expect(roomLoot(11, 3), roomLoot(11, 3));
      expect(roomLoot(11, 3), isNot(roomLoot(11, 4)));
    });

    // On the web an int is a double, so a seed above 2^53 would be rounded and
    // the browser build would resolve a different run from the same save.
    test('derived seeds stay inside 31 bits', () {
      final GameRandom run = GameRandom(0x7fffffff);

      for (final String stream in <String>['loot', 'traits', 'room:9999', '']) {
        final int seed = run.fork(stream).seed;
        expect(seed, greaterThanOrEqualTo(0));
        expect(seed, lessThan(0x80000000));
      }
    });

    test('between includes both ends', () {
      final GameRandom random = GameRandom(5);
      final Set<int> seen = <int>{
        for (int i = 0; i < 200; i++) random.between(1, 3),
      };

      expect(seen, <int>{1, 2, 3});
    });

    test('a certainty is certain and an impossibility never happens', () {
      final GameRandom random = GameRandom(5);

      for (int i = 0; i < 50; i++) {
        expect(random.chance(1), isTrue);
        expect(random.chance(0), isFalse);
      }
    });

    test('weighted never returns a zero-weighted entry', () {
      final GameRandom random = GameRandom(5);
      final Map<String, double> table = <String, double>{
        'common': 90,
        'rare': 10,
        'disabled': 0,
      };

      final Set<String> seen = <String>{
        for (int i = 0; i < 500; i++) random.weighted(table),
      };

      expect(seen, <String>{'common', 'rare'});
    });

    test('weighted follows the weights', () {
      final GameRandom random = GameRandom(5);
      int rare = 0;
      for (int i = 0; i < 2000; i++) {
        if (random.weighted(<String, double>{'common': 90, 'rare': 10}) ==
            'rare') {
          rare++;
        }
      }

      expect(rare, greaterThan(120));
      expect(rare, lessThan(280));
    });

    test('a table with nothing in it is a content bug, not a null', () {
      expect(
        () => GameRandom(5).weighted(<String, double>{'off': 0}),
        throwsStateError,
      );
    });

    test('picking from nothing throws rather than answering null', () {
      expect(() => GameRandom(5).pick(<String>[]), throwsStateError);
    });

    test('shuffling leaves the original alone', () {
      const List<int> original = <int>[1, 2, 3, 4, 5, 6, 7, 8];
      final List<int> shuffled = GameRandom(5).shuffled(original);

      expect(original, <int>[1, 2, 3, 4, 5, 6, 7, 8]);
      expect(shuffled..sort(), original);
    });

    test('a sample is distinct and capped by what there is', () {
      final List<int> drawn = GameRandom(5).sample(<int>[1, 2, 3], 10);

      expect(drawn.toSet().length, drawn.length);
      expect(drawn.length, 3);
    });
  });
}
