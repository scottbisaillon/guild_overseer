import 'combatant.dart';
import 'skill.dart';
import 'targeting.dart';

/// The skill a unit is about to fire and everyone it lands on.
class RotationDecision {
  const RotationDecision({required this.slot, required this.targets});

  final SkillSlot slot;
  final List<Combatant> targets;

  SkillDefinition get skill => slot.definition;
}

/// Picks the one skill [unit] fires on this beat, or null when it does nothing.
///
/// Walks the rotation in order and takes the first slot that is both off
/// cooldown and has something to resolve against. One skill per beat — the rest
/// wait for the next one.
RotationDecision? selectSkill({
  required Combatant unit,
  required Combatant? currentTarget,
  required List<Combatant> units,
}) {
  if (!unit.isAlive || !unit.canAct) {
    return null;
  }

  for (final SkillSlot slot in unit.rotation) {
    if (!slot.isReady) {
      continue;
    }
    final List<Combatant> targets = resolveSkillTargets(
      unit: unit,
      skill: slot.definition,
      currentTarget: currentTarget,
      units: units,
    );
    if (targets.isEmpty) {
      continue;
    }
    return RotationDecision(slot: slot, targets: targets);
  }
  return null;
}
