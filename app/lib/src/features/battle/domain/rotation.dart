import 'arena_layout.dart';
import 'combatant.dart';
import 'skill.dart';
import '../../../core/domain/skill_effect.dart';
import 'targeting.dart';

/// One effect of a skill, paired with everyone it landed on.
class ResolvedEffect {
  const ResolvedEffect({required this.effect, required this.targets});

  final SkillEffect effect;

  /// Never empty: an effect with nothing to land on is dropped before it gets
  /// this far.
  final List<Combatant> targets;
}

/// The skill a unit is about to fire, and what each part of it resolves to.
class RotationDecision {
  const RotationDecision({required this.slot, required this.effects});

  final SkillSlot slot;

  /// The effects that found something to land on, in resolution order.
  final List<ResolvedEffect> effects;

  SkillDefinition get skill => slot.definition;

  /// Everyone this skill touches, in the order it touches them, each appearing
  /// once. Two effects hitting the same unit is one unit as far as the
  /// renderer is concerned.
  List<Combatant> get targets {
    final Map<String, Combatant> unique = <String, Combatant>{};
    for (final ResolvedEffect resolved in effects) {
      for (final Combatant target in resolved.targets) {
        unique.putIfAbsent(target.id, () => target);
      }
    }
    return unique.values.toList(growable: false);
  }
}

/// Picks the one skill [unit] fires on this beat, or null when it does nothing.
///
/// Walks the rotation in order and takes the first slot that is off cooldown
/// and has something to resolve against. A skill fires when *any* of its
/// effects finds a target — so a strike that also heals the caster still
/// strikes when nobody needs healing — and the effects that found nothing are
/// dropped rather than blocking the skill.
///
/// One skill per beat; the rest wait for the next one.
RotationDecision? selectSkill({
  required Combatant unit,
  required Combatant? currentTarget,
  required List<Combatant> units,
  required ArenaLayout layout,
}) {
  if (!unit.isAlive || !unit.canAct) {
    return null;
  }

  for (final SkillSlot slot in unit.rotation) {
    if (!slot.isReady) {
      continue;
    }
    final List<ResolvedEffect> resolved = <ResolvedEffect>[];
    for (final EffectSpec spec in slot.definition.effects) {
      final List<Combatant> targets = resolveTargets(
        selector: spec.selector,
        caster: unit,
        currentTarget: currentTarget,
        units: units,
        layout: layout,
      );
      if (targets.isEmpty) {
        continue;
      }
      resolved.add(ResolvedEffect(effect: spec.effect, targets: targets));
    }
    if (resolved.isEmpty) {
      continue;
    }
    return RotationDecision(slot: slot, effects: resolved);
  }
  return null;
}
