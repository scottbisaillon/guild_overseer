/// Comparing accumulated simulated time against a threshold.
///
/// Time in the simulation is reached by adding or subtracting a fixed step over
/// and over, and that does not land on round numbers: counting 5 seconds down
/// by sixtieths leaves about 1.3e-14 behind. Compared with `<= 0` that residue
/// reads as "not ready yet", so a cooldown came up one step *after* the beat it
/// should have landed on — and then waited a whole beat more for the next one.
///
/// The effect was that every cooldown an exact multiple of the global cooldown
/// silently ran a second long, and inconsistently: 5s and 6s cooldowns drifted
/// while 1s, 10s and 12s happened to land clean. Authored numbers have to mean
/// what they say, so every countdown in the simulation goes through here.
abstract final class GameTime {
  /// Slack allowed when comparing simulated time.
  ///
  /// A microsecond: six orders of magnitude above the worst drift a minute of
  /// accumulation produces, and sixty thousand times smaller than one
  /// simulation step, so it can absorb the error without ever swallowing a
  /// real interval.
  static const double epsilon = 1e-6;

  /// Counts [remaining] down by [dt], snapping to zero once it is close enough
  /// that only accumulated error separates it.
  static double countDown(double remaining, double dt) {
    final double next = remaining - dt;
    return next < epsilon ? 0 : next;
  }

  /// Whether [accumulated] has reached [interval], allowing for drift.
  static bool hasElapsed(double accumulated, double interval) =>
      accumulated >= interval - epsilon;
}
