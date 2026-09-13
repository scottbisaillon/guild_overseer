import 'dart:math' as math;

import '../../../core/domain/skill_effect.dart';
import '../../../core/domain/stat.dart';
import '../../../core/domain/status.dart';
import '../../../core/events/game_event.dart';
import 'combatant.dart';

/// Everything an effect needs in order to resolve, in one bundle.
///
/// Passed down rather than reached for, so an effect cannot quietly acquire a
/// dependency on the simulation and stop being testable on its own. The random
/// source in particular is threaded rather than global: a fight is a pure
/// function of its roster and its seed, and every roll has to come from the
/// same stream for that to keep being true.
class ResolutionContext {
  const ResolutionContext({
    required this.caster,
    required this.label,
    required this.random,
    required this.emit,
    this.statSnapshot,
  });

  /// Who is doing this. Named in the events; also the unit whose stats size
  /// the effect, unless [statSnapshot] says otherwise.
  final Combatant caster;

  /// What to call this in the log — a skill's name, or a status's.
  final String label;

  final math.Random random;

  /// Where the facts go. The simulation's own event sink.
  final void Function(GameEvent event) emit;

  /// Stats frozen at some earlier moment, used in place of the caster's live
  /// ones.
  ///
  /// This is what makes a damage over time behave: its ticks are as strong as
  /// the unit that applied it was when it applied it, whatever has happened to
  /// that unit since — including dying.
  final Map<Stat, double>? statSnapshot;

  double statValue(Stat stat) =>
      statSnapshot?[stat] ?? caster.stats.value(stat);
}

/// Carries out one effect against everyone it landed on.
///
/// The single place that knows what any effect *does*. Everything else in the
/// fight — rotations, targeting, statuses, the renderer — deals in effects as
/// data and never in what they mean.
void resolveEffect(
  SkillEffect effect,
  List<Combatant> targets,
  ResolutionContext context,
) {
  for (final Combatant target in targets) {
    // Exhaustive over the sealed hierarchy: adding an effect kind fails to
    // compile here until it is given a meaning, which is the point of the set
    // being closed.
    switch (effect) {
      case DamageEffect():
        _resolveDamage(effect, target, context);
      case HealEffect():
        _resolveHeal(effect, target, context);
      case ApplyStatusEffect():
        _resolveApplyStatus(effect, target, context);
      case RemoveStatusEffect():
        _resolveRemoveStatus(effect, target, context);
    }
  }
}

/// The authored magnitude, scaled by whoever caused it and rolled.
///
/// Rolled once per target, so an area skill spreads rather than landing for
/// one number, and rounded to whole numbers so the floating combat text stays
/// readable.
double _magnitude(MagnitudeEffect effect, ResolutionContext context) {
  final double scaled =
      effect.coefficient * context.statValue(effect.scalesWith);
  final double roll = (1 - effect.variance) +
      context.random.nextDouble() * effect.variance * 2;
  return (scaled * roll).roundToDouble();
}

void _resolveDamage(
  DamageEffect effect,
  Combatant target,
  ResolutionContext context,
) {
  // Mitigation is the target's business and applies however the damage
  // arrived — a swing, a bleed tick, a reflected hit.
  final double incoming = _magnitude(effect, context) *
      target.stats.value(Stat.damageTakenMultiplier);
  final double dealt = target.applyDamage(incoming.roundToDouble());
  context.emit(DamageDealt(
    sourceId: context.caster.id,
    sourceName: context.caster.name,
    targetId: target.id,
    targetName: target.name,
    skillName: context.label,
    amount: dealt,
    remainingHealth: target.health,
  ));
  if (!target.isAlive) {
    context.emit(UnitDied(
      unitId: target.id,
      unitName: target.name,
      faction: target.faction,
    ));
  }
}

void _resolveHeal(
  HealEffect effect,
  Combatant target,
  ResolutionContext context,
) {
  final double healed = target.applyHeal(_magnitude(effect, context));
  context.emit(HealApplied(
    sourceId: context.caster.id,
    sourceName: context.caster.name,
    targetId: target.id,
    targetName: target.name,
    skillName: context.label,
    amount: healed,
    remainingHealth: target.health,
  ));
}

void _resolveApplyStatus(
  ApplyStatusEffect effect,
  Combatant target,
  ResolutionContext context,
) {
  // The dead carry nothing.
  if (!target.isAlive) {
    return;
  }
  final ActiveStatus status = target.statuses.apply(
    effect.status,
    sourceId: context.caster.id,
    sourceName: context.caster.name,
    statSnapshot: snapshotFor(effect.status, context),
    stacks: effect.stacks,
  );
  context.emit(StatusApplied(
    sourceId: context.caster.id,
    sourceName: context.caster.name,
    targetId: target.id,
    targetName: target.name,
    statusId: status.id,
    statusName: status.definition.name,
    stacks: status.stacks,
    duration: status.remaining,
    presentation: effect.status.presentation,
  ));
}

void _resolveRemoveStatus(
  RemoveStatusEffect effect,
  Combatant target,
  ResolutionContext context,
) {
  final List<ActiveStatus> removed =
      target.statuses.removeMatching(effect.tags, count: effect.count);
  for (final ActiveStatus status in removed) {
    context.emit(StatusEnded(
      unitId: target.id,
      unitName: target.name,
      statusId: status.id,
      statusName: status.definition.name,
      expired: false,
    ));
  }
}

/// The applier's scaling stats, read once, for a status that ticks.
///
/// Only the stats its ticks actually use, so a status that does not tick
/// carries nothing.
Map<Stat, double> snapshotFor(
  StatusDefinition definition,
  ResolutionContext context,
) {
  if (!definition.ticks) {
    return const <Stat, double>{};
  }
  return <Stat, double>{
    for (final SkillEffect effect in definition.onTick)
      if (effect case final MagnitudeEffect magnitude)
        magnitude.scalesWith: context.statValue(magnitude.scalesWith),
  };
}
