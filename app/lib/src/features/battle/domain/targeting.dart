import '../../../core/domain/faction.dart';
import '../../../core/domain/target_selector.dart';
import 'arena_layout.dart';
import 'combatant.dart';

/// Target selection, as pure functions over plain data.
///
/// Nothing here knows about Flame, Flutter, or the game loop, which is what
/// makes the rules testable on their own.
///
/// One resolver serves everything that has to answer "who?": a unit picking an
/// opponent to attack, and each effect of each skill picking what it lands on.
/// They differ only in the [TargetSelector] handed in.

/// Everyone [selector] picks out, in the order they should be dealt with.
///
/// An empty result is a normal answer, not a failure — it is how a heal with
/// nobody wounded, or a skill whose target just died, gets skipped so the
/// rotation can fall through to the next one.
List<Combatant> resolveTargets({
  required TargetSelector selector,
  required Combatant caster,
  required Combatant? currentTarget,
  required List<Combatant> units,
  required ArenaLayout layout,
}) {
  final Combatant? anchor = switch (selector.anchor) {
    TargetAnchor.caster => caster,
    TargetAnchor.currentTarget => currentTarget,
  };
  // A selector hung off a target that has died selects nobody.
  if (anchor == null || !anchor.isAlive) {
    return const <Combatant>[];
  }

  final Faction wanted = switch (selector.side) {
    TargetSide.allies => caster.faction,
    TargetSide.enemies => caster.faction.opposing,
  };

  final List<Combatant> pool = <Combatant>[];
  for (final Combatant candidate in units) {
    if (!candidate.isAlive || candidate.faction != wanted) {
      continue;
    }
    if (candidate.id == caster.id && !selector.includeSelf) {
      continue;
    }
    if (!_matchesShape(selector.shape, candidate, anchor)) {
      continue;
    }
    if (!_matchesFilters(selector.filters, candidate)) {
      continue;
    }
    pool.add(candidate);
  }

  // Ranking decides who makes a cut. With no cut there is nothing to decide,
  // so the pool keeps formation order rather than being shuffled into an
  // ordering nobody asked for.
  if (selector.takesEveryone || pool.length <= selector.count) {
    return List<Combatant>.unmodifiable(pool);
  }

  final List<_Ranked> ranked = <_Ranked>[
    for (int i = 0; i < pool.length; i++)
      (
        unit: pool[i],
        index: i,
        score: _score(selector, caster, pool[i], layout),
      ),
  ]..sort(_byScoreThenFormation);

  return List<Combatant>.unmodifiable(<Combatant>[
    for (final _Ranked entry in ranked.take(selector.count)) entry.unit,
  ]);
}

/// Picks the opponent [unit] should attack, or null when no opponent is left.
///
/// Self-targeting and same-faction targeting are impossible by construction:
/// the unit's priority selects from the opposing side only.
Combatant? selectTarget({
  required Combatant unit,
  required List<Combatant> candidates,
  required ArenaLayout layout,
}) {
  final List<Combatant> picked = resolveTargets(
    selector: unit.priority.selector,
    caster: unit,
    currentTarget: null,
    units: candidates,
    layout: layout,
  );
  return picked.isEmpty ? null : picked.first;
}

typedef _Ranked = ({Combatant unit, int index, double score});

/// Lower score wins; equal scores keep formation order, so a tie resolves the
/// same way every time rather than however the sort happened to land.
int _byScoreThenFormation(_Ranked a, _Ranked b) {
  final int byScore = a.score.compareTo(b.score);
  return byScore != 0 ? byScore : a.index.compareTo(b.index);
}

bool _matchesShape(TargetShape shape, Combatant candidate, Combatant anchor) =>
    switch (shape) {
      TargetShape.anchorOnly => candidate.id == anchor.id,
      TargetShape.sameColumn => candidate.column == anchor.column,
      TargetShape.sameRow => candidate.row == anchor.row,
      TargetShape.all => true,
    };

bool _matchesFilters(List<TargetFilter> filters, Combatant candidate) {
  for (final TargetFilter filter in filters) {
    final bool ok = switch (filter) {
      WoundedFilter() => candidate.isWounded,
      HealthBelowFilter(:final double fraction) =>
        candidate.healthFraction < fraction,
    };
    if (!ok) {
      return false;
    }
  }
  return true;
}

const double _tieBreakWeight = 0.01;

/// Lower is better. Every ordering folds down to one comparable number so ties
/// break on distance without a second pass.
double _score(
  TargetSelector selector,
  Combatant caster,
  Combatant candidate,
  ArenaLayout layout,
) {
  final double distanceSquared = layout.distanceSquared(
    caster.faction,
    caster.row,
    caster.column,
    candidate.faction,
    candidate.row,
    candidate.column,
  );

  // Distance is the universal tie-breaker. It is normalised against the arena
  // and then scaled down hard, so it orders equal candidates without ever
  // outweighing the primary term it is added to.
  final double proximity = selector.tieBreakByDistance
      ? distanceSquared / (layout.width * layout.width) * _tieBreakWeight
      : 0;

  return switch (selector.order) {
    TargetOrder.nearest => distanceSquared,
    TargetOrder.lowestHealthFraction => candidate.healthFraction + proximity,
    TargetOrder.highestMaxHealth => -candidate.maxHealth + proximity,
    TargetOrder.frontline => candidate.column + proximity,
    TargetOrder.backline => -candidate.column + proximity,
    TargetOrder.preferredRole =>
      (candidate.role == selector.preferredRole ? 0 : 1) + proximity,
  };
}
