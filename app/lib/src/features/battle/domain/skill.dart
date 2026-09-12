import 'dart:math' as math;

import '../../../core/domain/skill_kind.dart';

/// Who a skill resolves against once it fires.
enum SkillTargeting {
  /// A single opponent — whoever the unit's target priority picked.
  opposingPriority,

  /// Every living opponent sharing a column with the unit's current target.
  opposingColumn,

  /// The most wounded living ally, which may be the caster itself. Resolves to
  /// nothing when the whole side is at full health, so the skill is skipped and
  /// the rotation falls through to the next one.
  lowestHealthAlly,
}

/// A skill as authored: static data, never mutated at runtime.
///
/// Skills are first-class data rather than a switch case inside an attack
/// method — adding one is adding an entry, not editing combat code. These are
/// declared in Dart for the mockup; they move to a JSON asset read by
/// `DataRepository` when the data layer lands.
class SkillDefinition {
  const SkillDefinition({
    required this.id,
    required this.name,
    required this.kind,
    required this.delivery,
    required this.targeting,
    required this.power,
    required this.cooldown,
    this.isBasic = false,
  });

  final String id;
  final String name;
  final SkillKind kind;
  final SkillDelivery delivery;
  final SkillTargeting targeting;

  /// Damage or healing before variance.
  final double power;

  /// Seconds before this skill can fire again.
  final double cooldown;

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
