import 'dart:math' as math;

import '../../../core/domain/presentation.dart';
import '../../../core/domain/skill_effect.dart';

/// A skill as authored: static data, never mutated at runtime.
///
/// A skill is a list of effects, not a thing that does one thing. That is what
/// makes "heavy damage to the target, and a tenth of it back to the caster"
/// two rows rather than a special case — and what stops the combat code
/// growing a branch every time a piece of content is added. These are declared
/// in Dart for the mockup; they move to a JSON asset read by `DataRepository`
/// when the data layer lands.
class SkillDefinition {
  const SkillDefinition({
    required this.id,
    required this.name,
    required this.effects,
    required this.cooldown,
    this.presentation = PresentationSpec.none,
    this.isBasic = false,
  });

  final String id;
  final String name;

  /// What this skill does, in resolution order. Each carries its own targeting,
  /// so the parts of a skill need not land on the same people.
  final List<EffectSpec> effects;

  /// Seconds before this skill can fire again.
  final double cooldown;

  /// How this looks when it fires. Ids the renderer resolves, never types it
  /// branches on.
  final PresentationSpec presentation;

  /// A basic attack shares the global cooldown, so a unit is never left with
  /// nothing to do when its specials are cooling down.
  final bool isBasic;

}

/// One slot of a unit's rotation: a skill plus its live cooldown.
///
/// Rotation order is priority order — the first ready slot fires. To favour a
/// heavy hitter, put it above the basic attack.
class SkillSlot {
  SkillSlot(this.definition);

  final SkillDefinition definition;

  double _remaining = 0;

  double get remaining => _remaining;

  bool get isReady => _remaining <= 0;

  /// Cooldowns advance every tick regardless of what the unit is doing, so
  /// waiting on a target never costs cooldown progress.
  void tick(double dt) {
    if (_remaining > 0) {
      _remaining = math.max(0, _remaining - dt);
    }
  }

  void trigger() => _remaining = definition.cooldown;

  void reset() => _remaining = 0;
}
