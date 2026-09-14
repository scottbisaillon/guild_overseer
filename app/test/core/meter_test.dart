import 'package:flutter_test/flutter_test.dart';
import 'package:guild_overseer/src/core/domain/meter.dart';

/// The clamp is the whole reason this type exists, so it is what is pinned.
void main() {
  group('Meter', () {
    test('holds the value it was given when it is in range', () {
      expect(Meter(42).value, 42);
    });

    test('clamps above the ceiling rather than rejecting', () {
      expect(Meter(140).value, Meter.maximum);
    });

    test('clamps below the floor', () {
      expect(Meter(-30).value, Meter.minimum);
    });

    test('draining past empty stops at empty', () {
      expect(Meter(10).adjustedBy(-40), Meter.empty);
    });

    test('filling past full stops at full', () {
      expect(Meter(90).adjustedBy(40), Meter.full);
    });

    test('stacked adjustments cannot dig a hole to climb out of', () {
      // Three hits that would total -60 from a meter holding 20. If the clamp
      // were applied only at the end this would read as 20, because -40 of it
      // would have been banked at -40.
      final Meter drained =
          Meter(20).adjustedBy(-30).adjustedBy(-30).adjustedBy(10);

      expect(drained.value, 10);
    });

    test('fraction spans the range', () {
      expect(Meter.empty.fraction, 0);
      expect(Meter.half.fraction, 0.5);
      expect(Meter.full.fraction, 1);
    });

    test('two meters holding the same value are the same value', () {
      expect(Meter(60), Meter(30).adjustedBy(30));
    });

    test('round-trips through json', () {
      expect(Meter.fromJson(Meter(37.5).toJson()), Meter(37.5));
    });

    test('a missing value reads as empty rather than crashing a save load', () {
      expect(Meter.fromJson(null), Meter.empty);
    });
  });
}
