import 'dart:math' as math;

/// What a level costs, and what a pile of experience is worth.
///
/// A member's level is not stored — it is read off their experience through
/// here. Storing both invites the two to disagree, and the first time they do
/// it is in a save file somebody has already played fifty hours of. One number
/// is the truth and the other is a view of it.
///
/// The curve itself is first-pass tuning: each level costs a flat amount more
/// than the last, so the total to reach level L is quadratic. Levels are
/// cheap early and the cost grows steadily rather than exploding, which suits
/// a game where a member is expected to reach the cap over a campaign rather
/// than be chased to it. Retuning is editing [_costPerLevelStep].
abstract final class ExperienceCurve {
  /// The cap from [[docs/systems/members]]. A member at the cap keeps earning
  /// experience — it simply stops buying levels.
  static const int maxLevel = 60;

  static const int minLevel = 1;

  /// Level 2 costs this; level 3 costs twice this; and so on.
  static const int _costPerLevelStep = 100;

  /// Experience needed to go from [level] to the next one.
  ///
  /// Zero at the cap, which is the honest answer rather than a special case
  /// the caller has to know about.
  static int costOfLevel(int level) {
    if (level >= maxLevel) {
      return 0;
    }
    return _costPerLevelStep * math.max(level, minLevel);
  }

  /// Total experience a member must have accumulated to be [level].
  ///
  /// Closed form rather than a sum, so a level lookup stays cheap no matter
  /// where the cap ends up: the cost is `step x level`, so the total is
  /// `step x (1 + 2 + ... + level-1)`.
  static int totalFor(int level) {
    final int capped = level.clamp(minLevel, maxLevel);
    return _costPerLevelStep * (capped - 1) * capped ~/ 2;
  }

  /// The level [experience] buys. Never below [minLevel], never above
  /// [maxLevel], and never negative however odd the input.
  static int levelFor(int experience) {
    if (experience <= 0) {
      return minLevel;
    }
    // Invert totalFor: step x L x (L-1) / 2 <= xp. Solved rather than looped,
    // then walked one step either way to absorb floating point error at the
    // boundary — which is exactly where a level-up happens, so it is exactly
    // where being off by one would be noticed.
    final double solved =
        (1 + math.sqrt(1 + 8 * experience / _costPerLevelStep)) / 2;
    int level = solved.floor().clamp(minLevel, maxLevel);
    while (level < maxLevel && totalFor(level + 1) <= experience) {
      level++;
    }
    while (level > minLevel && totalFor(level) > experience) {
      level--;
    }
    return level;
  }

  /// How far [experience] is through its current level, 0.0 to 1.0. Always
  /// 1.0 at the cap, where there is nothing left to fill.
  static double progressWithin(int experience) {
    final int level = levelFor(experience);
    final int cost = costOfLevel(level);
    if (cost <= 0) {
      return 1;
    }
    return ((experience - totalFor(level)) / cost).clamp(0.0, 1.0);
  }

  /// Experience still owed before the next level. Zero at the cap.
  static int remainingToNextLevel(int experience) {
    final int level = levelFor(experience);
    if (level >= maxLevel) {
      return 0;
    }
    return totalFor(level + 1) - experience;
  }
}
