import '../../../core/domain/faction.dart';
import '../../../core/domain/target_priority.dart';
import 'arena_layout.dart';
import 'combatant.dart';
import 'skill_effect.dart';

/// Target selection, as pure functions over plain data.
///
/// Nothing here knows about Flame, Flutter, or the game loop, which is what
/// makes the rules testable on their own.

/// Picks the opponent [unit] should attack, or null when no opponent is left.
///
/// Self-targeting and same-faction targeting are impossible by construction:
/// only living members of the opposing faction are considered.
Combatant? selectTarget({
  required Combatant unit,
  required List<Combatant> candidates,
  required ArenaLayout layout,
}) {
  final List<Combatant> opponents = candidates
      .where((Combatant c) => c.isAlive && c.faction == unit.faction.opposing)
      .toList(growable: false);
  if (opponents.isEmpty) {
    return null;
  }

  Combatant? best;
  double bestScore = double.infinity;
  for (final Combatant candidate in opponents) {
    final double score = _score(unit, candidate, layout);
    if (score < bestScore) {
      bestScore = score;
      best = candidate;
    }
  }
  return best;
}

const double _tieBreakWeight = 0.01;

/// Lower is better. Every priority folds down to one comparable number so ties
/// break on distance without a second pass.
double _score(Combatant unit, Combatant candidate, ArenaLayout layout) {
  final double distanceSquared = layout.distanceSquared(
    unit.faction,
    unit.row,
    unit.column,
    candidate.faction,
    candidate.row,
    candidate.column,
  );

  // Distance is the universal tie-breaker. It is normalised against the arena
  // and then scaled down hard, so it orders equal candidates without ever
  // outweighing the primary term it is added to.
  final double proximity =
      distanceSquared / (layout.width * layout.width) * _tieBreakWeight;

  return switch (unit.priority) {
    TargetPriority.nearest => distanceSquared,
    TargetPriority.weakest => candidate.healthFraction + proximity,
    TargetPriority.strongest => -candidate.maxHealth + proximity,
    TargetPriority.frontline => candidate.column + proximity,
    TargetPriority.backline => -candidate.column + proximity,
    TargetPriority.healerFirst =>
      (candidate.role == unit.priority.preferredRole ? 0 : 1) + proximity,
  };
}

/// The most wounded living member of [faction], or null when the whole side is
/// at full health. A healer with nothing to heal skips the skill rather than
/// burning its beat on a no-op.
Combatant? lowestHealthAlly(List<Combatant> units, Faction faction) {
  Combatant? best;
  for (final Combatant unit in units) {
    if (!unit.isAlive || unit.faction != faction || !unit.isWounded) {
      continue;
    }
    if (best == null || unit.healthFraction < best.healthFraction) {
      best = unit;
    }
  }
  return best;
}

/// Everyone one effect of a skill resolves against, given the caster's current
/// target.
///
/// An empty result means that effect has nothing to land on, and is skipped.
List<Combatant> resolveSkillTargets({
  required Combatant unit,
  required SkillTargeting targeting,
  required Combatant? currentTarget,
  required List<Combatant> units,
}) {
  switch (targeting) {
    case SkillTargeting.opposingPriority:
      if (currentTarget == null || !currentTarget.isAlive) {
        return const <Combatant>[];
      }
      return <Combatant>[currentTarget];

    case SkillTargeting.opposingColumn:
      if (currentTarget == null || !currentTarget.isAlive) {
        return const <Combatant>[];
      }
      return units
          .where((Combatant c) =>
              c.isAlive &&
              c.faction == currentTarget.faction &&
              c.column == currentTarget.column)
          .toList(growable: false);

    case SkillTargeting.lowestHealthAlly:
      final Combatant? wounded = lowestHealthAlly(units, unit.faction);
      return wounded == null ? const <Combatant>[] : <Combatant>[wounded];
  }
}
