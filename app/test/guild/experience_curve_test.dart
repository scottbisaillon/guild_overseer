import 'package:flutter_test/flutter_test.dart';
import 'package:guild_overseer/src/features/guild/domain/experience_curve.dart';

/// A member's level is derived from experience on every read, so the inversion
/// has to be exact at the boundaries — which is precisely where a level-up
/// happens and where being off by one would be visible.
void main() {
  group('ExperienceCurve', () {
    test('a member with nothing is level one', () {
      expect(ExperienceCurve.levelFor(0), 1);
      expect(ExperienceCurve.totalFor(1), 0);
    });

    test('nonsense experience still reads as level one', () {
      expect(ExperienceCurve.levelFor(-500), 1);
    });

    test('totals and costs agree at every level', () {
      for (int level = 1; level < ExperienceCurve.maxLevel; level++) {
        expect(
          ExperienceCurve.totalFor(level) + ExperienceCurve.costOfLevel(level),
          ExperienceCurve.totalFor(level + 1),
          reason: 'the cost of level $level should close the gap above it',
        );
      }
    });

    test('every threshold is the exact point the level turns over', () {
      for (int level = 2; level <= ExperienceCurve.maxLevel; level++) {
        final int threshold = ExperienceCurve.totalFor(level);

        expect(ExperienceCurve.levelFor(threshold), level);
        expect(ExperienceCurve.levelFor(threshold - 1), level - 1);
      }
    });

    test('levels get more expensive, never cheaper', () {
      for (int level = 1; level < ExperienceCurve.maxLevel - 1; level++) {
        expect(
          ExperienceCurve.costOfLevel(level + 1),
          greaterThan(ExperienceCurve.costOfLevel(level)),
        );
      }
    });

    test('the cap holds however much experience piles up', () {
      expect(ExperienceCurve.levelFor(50000000), ExperienceCurve.maxLevel);
      expect(ExperienceCurve.costOfLevel(ExperienceCurve.maxLevel), 0);
      expect(ExperienceCurve.remainingToNextLevel(50000000), 0);
      expect(ExperienceCurve.progressWithin(50000000), 1);
    });

    test('progress runs from nothing to nearly everything within a level', () {
      final int start = ExperienceCurve.totalFor(5);
      final int cost = ExperienceCurve.costOfLevel(5);

      expect(ExperienceCurve.progressWithin(start), 0);
      expect(ExperienceCurve.progressWithin(start + cost ~/ 2), closeTo(0.5, 0.01));
      expect(ExperienceCurve.remainingToNextLevel(start), cost);
    });
  });
}
