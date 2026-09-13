import 'combat_role.dart';

/// Which side of the fight a selector draws from, relative to the caster.
enum TargetSide {
  /// The caster's own side.
  allies,

  /// The side the caster is fighting.
  enemies,
}

/// Which unit a selector measures its shape against.
enum TargetAnchor {
  /// The caster itself.
  caster,

  /// The opponent the caster has locked onto. A selector anchored here finds
  /// nobody when that target is gone, which is what makes a skill needing one
  /// fall through to the next in the rotation.
  currentTarget,
}

/// How the candidate pool is narrowed around the anchor.
enum TargetShape {
  /// The anchor itself and nobody else.
  anchorOnly,

  /// Everyone in the anchor's column — its rank in the formation.
  sameColumn,

  /// Everyone in the anchor's row.
  sameRow,

  /// The whole side, ignoring where the anchor stands.
  all,
}

/// How candidates are ranked when there are more of them than are wanted.
///
/// Lower is better in every case; the ordering functions live with the
/// resolver, so adding a way to rank is adding a value here and an arm there.
enum TargetOrder {
  /// Closest by distance across the arena.
  nearest,

  /// Lowest health as a proportion of maximum. Finishes kills, and picks the
  /// most urgent patient.
  lowestHealthFraction,

  /// Biggest health pool. Hunts the tank rather than the stragglers.
  highestMaxHealth,

  /// Nearest the centre line.
  frontline,

  /// Furthest from the centre line.
  backline,

  /// Units of [TargetSelector.preferredRole] before anyone else.
  preferredRole,
}

/// A condition a candidate must meet to be eligible.
///
/// Data, like effects: the resolver interprets these, they do not interpret
/// themselves. Being alive is not among them because it is never optional.
sealed class TargetFilter {
  const TargetFilter();
}

/// Below full health. A heal with nothing to mend selects nobody, and the
/// skill is skipped rather than wasted.
final class WoundedFilter extends TargetFilter {
  const WoundedFilter();
}

/// Below a proportion of maximum health — the execute threshold.
final class HealthBelowFilter extends TargetFilter {
  const HealthBelowFilter(this.fraction);

  final double fraction;
}

/// Who something lands on, composed rather than enumerated.
///
/// The four axes are orthogonal, so the combinations available to a designer
/// vastly outnumber the code paths behind them: "every enemy in my target's
/// column", "the three nearest enemies below 15% health", "the most wounded
/// ally including myself" are all this one type with different fields, and
/// none of them is a case in a switch somewhere.
///
/// This is what both a unit's standing target priority and a single effect's
/// targeting are expressed in — one mechanism, used in two places, rather than
/// two vocabularies that have to be kept in step.
class TargetSelector {
  const TargetSelector({
    required this.side,
    this.anchor = TargetAnchor.caster,
    this.shape = TargetShape.all,
    this.order = TargetOrder.nearest,
    this.filters = const <TargetFilter>[],
    this.count = 1,
    this.includeSelf = false,
    this.preferredRole,
    this.tieBreakByDistance = true,
  });

  /// A [count] meaning "everyone who qualifies".
  static const int unlimited = 0;

  final TargetSide side;
  final TargetAnchor anchor;
  final TargetShape shape;
  final TargetOrder order;
  final List<TargetFilter> filters;

  /// How many survive the ranking. [unlimited] takes everyone, in which case
  /// [order] is not consulted at all — ranking decides who makes a cut, and
  /// without a cut the pool keeps its natural formation order.
  final int count;

  /// Whether the caster may select itself. Off by default so an area attack
  /// does not hit its own caster by accident.
  final bool includeSelf;

  /// The role [TargetOrder.preferredRole] hunts.
  final CombatRole? preferredRole;

  /// Whether distance settles an otherwise equal ranking.
  ///
  /// True for hunting an opponent across the arena, where the nearer of two
  /// equal candidates is the obvious pick. False when ranking one's own side,
  /// where formation order is the more predictable tie-break and the distance
  /// between two allies means nothing.
  final bool tieBreakByDistance;

  bool get takesEveryone => count == unlimited;

  // ---------------------------------------------------------------------
  // Named shapes, so content reads as intent rather than as field soup.
  // ---------------------------------------------------------------------

  /// The opponent this unit has already locked onto.
  static const TargetSelector currentEnemy = TargetSelector(
    side: TargetSide.enemies,
    anchor: TargetAnchor.currentTarget,
    shape: TargetShape.anchorOnly,
  );

  /// Everyone standing in the same rank as the current target.
  static const TargetSelector currentEnemyColumn = TargetSelector(
    side: TargetSide.enemies,
    anchor: TargetAnchor.currentTarget,
    shape: TargetShape.sameColumn,
    count: unlimited,
  );

  /// The most wounded member of the caster's own side, which may be itself.
  static const TargetSelector mostWoundedAlly = TargetSelector(
    side: TargetSide.allies,
    order: TargetOrder.lowestHealthFraction,
    filters: <TargetFilter>[WoundedFilter()],
    includeSelf: true,
    tieBreakByDistance: false,
  );

  /// The caster itself.
  static const TargetSelector self = TargetSelector(
    side: TargetSide.allies,
    shape: TargetShape.anchorOnly,
    includeSelf: true,
  );

  TargetSelector copyWith({
    TargetOrder? order,
    int? count,
    CombatRole? preferredRole,
    List<TargetFilter>? filters,
  }) =>
      TargetSelector(
        side: side,
        anchor: anchor,
        shape: shape,
        order: order ?? this.order,
        filters: filters ?? this.filters,
        count: count ?? this.count,
        includeSelf: includeSelf,
        preferredRole: preferredRole ?? this.preferredRole,
        tieBreakByDistance: tieBreakByDistance,
      );
}
