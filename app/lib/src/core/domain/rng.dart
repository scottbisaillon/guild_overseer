import 'dart:math' as math;

/// A seeded source of randomness that can be split into independent streams.
///
/// Determinism is a feature here, not a testing convenience: an idle run is
/// resolved from a stored seed and has to produce the same outcome whether it
/// is played live, fast-forwarded after eight hours offline, or replayed in a
/// test. One shared [math.Random] cannot give that, because the sequence a
/// system sees then depends on how many numbers *every other system* drew
/// first — add one loot roll and every trait proc for the rest of the run
/// shifts. The bug that produces is unreproducible by construction.
///
/// So rolls come from named streams. [fork] derives a generator from this
/// one's seed and a name, deterministically, and two streams never disturb
/// each other. The idiom for anything that steps is to fork per step:
///
/// ```dart
/// final GameRandom run = GameRandom(activeRun.seed);
/// final GameRandom room = run.fork('room:$roomIndex');
/// final GameRandom loot = room.fork('loot');
/// ```
///
/// which also means nothing has to serialise a generator's *position*: the
/// seed and the step index are the whole of the state, and both are already
/// in the save.
class GameRandom {
  GameRandom(this.seed) : _random = math.Random(seed);

  /// The seed this generator draws from. Stored in the save; a run replayed
  /// from it resolves identically.
  final int seed;

  math.Random _random;

  /// An independent generator named [stream], derived from this seed.
  ///
  /// The same name off the same seed always gives the same generator, and
  /// different names give unrelated ones, so a system can start drawing
  /// without any other system's sequence moving.
  GameRandom fork(String stream) => GameRandom(_mix(seed, stream));

  /// Starts this generator's sequence over. The sequence is a function of the
  /// seed, so this replays exactly what it drew before.
  void restart() => _random = math.Random(seed);

  /// Uniform in [0, 1).
  double nextDouble() => _random.nextDouble();

  /// Uniform in [0, [max]). [max] must be positive.
  int nextInt(int max) => _random.nextInt(max);

  /// Uniform integer in [[min], [max]], both ends included — how a designer
  /// writes a range ("1–5 gold"), so content does not have to add one.
  int between(int min, int max) {
    assert(max >= min, 'between($min, $max): the range is inverted.');
    return min + _random.nextInt(max - min + 1);
  }

  /// Uniform double in [[min], [max]).
  double range(double min, double max) =>
      min + _random.nextDouble() * (max - min);

  /// True [probability] of the time. 0 never, 1 always, and both ends are
  /// honoured exactly rather than left to floating point luck.
  bool chance(double probability) {
    if (probability <= 0) {
      return false;
    }
    if (probability >= 1) {
      return true;
    }
    return _random.nextDouble() < probability;
  }

  /// One of [items], uniformly. Throws on an empty list: picking from nothing
  /// is a content bug, and returning null would push it somewhere else.
  T pick<T>(List<T> items) {
    if (items.isEmpty) {
      throw StateError('Nothing to pick from.');
    }
    return items[_random.nextInt(items.length)];
  }

  /// One of [weights]' keys, in proportion to its weight.
  ///
  /// The rarity roll: `{common: 70, uncommon: 25, rare: 5}`. Weights need not
  /// sum to anything in particular. Zero and negative weights are never
  /// chosen, which is how a table turns an entry off without removing it.
  T weighted<T>(Map<T, double> weights) {
    double total = 0;
    for (final double weight in weights.values) {
      if (weight > 0) {
        total += weight;
      }
    }
    if (total <= 0) {
      throw StateError('No entry in the table has a positive weight.');
    }
    double roll = _random.nextDouble() * total;
    for (final MapEntry<T, double> entry in weights.entries) {
      if (entry.value <= 0) {
        continue;
      }
      roll -= entry.value;
      if (roll < 0) {
        return entry.key;
      }
    }
    // Only reachable on floating point drift at the very top of the range.
    return weights.entries.lastWhere((MapEntry<T, double> e) => e.value > 0).key;
  }

  /// A shuffled copy. The original is left alone, because the lists this is
  /// handed are usually authored content.
  List<T> shuffled<T>(List<T> items) =>
      List<T>.of(items)..shuffle(_random);

  /// [count] distinct entries of [items], or all of them when there are not
  /// enough. The tavern pool draw.
  List<T> sample<T>(List<T> items, int count) =>
      shuffled(items).take(count).toList(growable: false);

  /// Folds [stream] into [seed].
  ///
  /// FNV-1a, masked to 31 bits. The mask is not decoration: on the web an int
  /// is a double, and a seed that does not fit in 32 bits would be rounded —
  /// silently making the browser build resolve a different run from the same
  /// save than the desktop build does.
  static int _mix(int seed, String stream) {
    int hash = 0x811c9dc5 ^ (seed & 0x7fffffff);
    for (final int unit in stream.codeUnits) {
      hash = (hash ^ unit) & 0xffffffff;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash & 0x7fffffff;
  }
}
