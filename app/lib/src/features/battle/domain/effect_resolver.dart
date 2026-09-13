import 'dart:math' as math;

import '../../../core/events/game_event.dart';
import 'combatant.dart';
import 'skill.dart';
import 'skill_effect.dart';

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
    required this.skill,
    required this.random,
    required this.emit,
  });

  final Combatant caster;

  /// The skill these effects belong to. Only used for naming in the events —
  /// effects themselves never branch on which skill carried them.
  final SkillDefinition skill;

  final math.Random random;

  /// Where the facts go. The simulation's own event sink.
  final void Function(GameEvent event) emit;
}

/// Carries out one effect against everyone it landed on.
///
/// The single place that knows what any effect *does*. Everything else in the
/// fight — rotations, targeting, the renderer — deals in effects as data and
/// never in what they mean.
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
    }
  }
}

/// The authored magnitude, scaled by the caster and rolled.
///
/// Rolled once per target, so an area skill spreads rather than landing for
/// one number, and rounded to whole numbers so the floating combat text stays
/// readable.
double _magnitude(SkillEffect effect, ResolutionContext context) {
  final double scaled =
      effect.coefficient * context.caster.stats.value(effect.scalesWith);
  final double roll = (1 - effect.variance) +
      context.random.nextDouble() * effect.variance * 2;
  return (scaled * roll).roundToDouble();
}

void _resolveDamage(
  DamageEffect effect,
  Combatant target,
  ResolutionContext context,
) {
  final double dealt = target.applyDamage(_magnitude(effect, context));
  context.emit(DamageDealt(
    sourceId: context.caster.id,
    sourceName: context.caster.name,
    targetId: target.id,
    targetName: target.name,
    skillName: context.skill.name,
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
    skillName: context.skill.name,
    amount: healed,
    remainingHealth: target.health,
  ));
}
