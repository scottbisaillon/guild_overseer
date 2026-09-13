import 'package:flutter_test/flutter_test.dart';
import 'package:guild_overseer/src/core/domain/game_time.dart';

/// Simulated time is reached by adding a fixed step over and over, which does
/// not land on round numbers. These pin the tolerance that stops that arithmetic
/// from making authored durations mean something other than what they say.
void main() {
  const double step = 1 / 60;

  group('GameTime', () {
    test('a countdown reaches exactly zero after its authored duration', () {
      // The bug this exists to prevent: 5 seconds counted down by sixtieths
      // leaves ~1.3e-14 behind, which reads as "not ready yet".
      for (final double duration in <double>[1, 2, 4, 5, 6, 8, 12, 30]) {
        double remaining = duration;
        for (int i = 0; i < (duration * 60).round(); i++) {
          remaining = GameTime.countDown(remaining, step);
        }
        expect(
          remaining,
          0,
          reason: '${duration}s should be spent after ${duration * 60} steps',
        );
      }
    });

    test('a countdown does not finish early', () {
      double remaining = 5;
      // One step short of the full duration.
      for (int i = 0; i < 299; i++) {
        remaining = GameTime.countDown(remaining, step);
      }
      expect(remaining, greaterThan(0));
    });

    test('the tolerance is far below anything the game measures', () {
      // Small enough that it can never swallow a real interval...
      expect(GameTime.epsilon, lessThan(step / 1000));
      // ...and large enough to absorb a minute of accumulated drift.
      expect(GameTime.epsilon, greaterThan(1e-9));
    });

    test('an interval is reached on its step, not the one after', () {
      double accumulated = 0;
      int ticks = 0;
      for (int i = 0; i < 360; i++) {
        accumulated += step;
        if (GameTime.hasElapsed(accumulated, 2)) {
          accumulated -= 2;
          ticks++;
        }
      }
      expect(ticks, 3, reason: '6 seconds at 2s intervals');
    });

    test('countDown never returns a negative', () {
      expect(GameTime.countDown(0.001, 1), 0);
    });
  });
}
