import '../../../core/domain/stat.dart';
import '../../../core/domain/target_selector.dart';

/// What one effect of a skill does when it lands.
///
/// Data, not behaviour: an effect describes itself and `effect_resolver.dart`
/// is the single place that knows how to carry any of them out. Adding a kind
/// means adding a class here and an arm there — and because the hierarchy is
/// `sealed`, the compiler names every site that has to learn about it.
///
/// Effects are deliberately not polymorphic. An effect that applied itself
/// would need the whole fight injected to do its job, and combat rules would
/// end up spread across a file per effect instead of one readable one.
sealed class SkillEffect {
  const SkillEffect();

  /// The stat this effect's magnitude is measured against.
  Stat get scalesWith;

  /// How far either side of the authored magnitude a roll may land, as a
  /// fraction. 0.15 means +/-15%.
  double get variance;

  /// Multiplier on [scalesWith]. A coefficient of 3 means "three times this
  /// unit's attack power" — which is why a sword that grants attack power
  /// makes every skill that scales off it hit harder, with no per-skill
  /// bookkeeping anywhere.
  double get coefficient;
}

/// Reduces the target's health.
final class DamageEffect extends SkillEffect {
  const DamageEffect({
    required this.coefficient,
    this.scalesWith = Stat.attackPower,
    this.variance = 0.15,
  });

  @override
  final double coefficient;

  @override
  final Stat scalesWith;

  @override
  final double variance;
}

/// Restores the target's health, never above its maximum.
final class HealEffect extends SkillEffect {
  const HealEffect({
    required this.coefficient,
    this.scalesWith = Stat.healPower,
    this.variance = 0.15,
  });

  @override
  final double coefficient;

  @override
  final Stat scalesWith;

  @override
  final double variance;
}

/// One effect of a skill, and who it lands on.
///
/// A skill is a list of these. They resolve in order, and each one that has
/// nobody to resolve against is simply skipped — so a skill that damages and
/// heals still does the half of its job that has a target.
///
/// Authored as a literal pairing rather than through per-kind shorthands: a
/// const constructor cannot build another object out of its own parameters, so
/// shorthands here would cost every skill in the game its const-ness.
class EffectSpec {
  const EffectSpec({required this.selector, required this.effect});

  /// Who this part of the skill lands on. Composed, so the parts of one
  /// skill need not agree about who they are for.
  final TargetSelector selector;

  final SkillEffect effect;
}
