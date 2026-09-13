/// A number about a unit that other systems are allowed to change.
///
/// Adding a stat is adding a value here plus a base for it — nothing switches
/// on this enum, so nothing else has to be edited. The point of routing every
/// number through one vocabulary is that gear, buffs, auras, traits and
/// passives never need their own path into a unit: they all describe
/// themselves as modifiers to these, and the combat maths never asks where a
/// number came from.
enum Stat {
  /// The unit's health ceiling. Live: [Combatant] reads it every frame.
  maxHealth(defaultValue: 100, minimum: 1),

  /// Seconds between actions. Live: gates every skill a unit fires.
  globalCooldown(defaultValue: 1, minimum: 0.05),

  /// Scaling stat for damaging skills. Declared for the effect pipeline, which
  /// is where skills stop carrying raw power numbers; nothing reads it yet.
  attackPower(defaultValue: 10, minimum: 0),

  /// Scaling stat for healing skills. Not read yet — see [attackPower].
  healPower(defaultValue: 10, minimum: 0),

  /// Flat physical mitigation. Not read yet — see [attackPower].
  armour(defaultValue: 0, minimum: 0),

  /// Scales every point of damage this unit receives. Live: applied by the
  /// effect resolver. A modifier of -0.15 makes the unit take 15% less.
  ///
  /// Untyped for now — mitigating physical damage specifically needs damage
  /// types and modifiers that can be conditioned on a tag, neither of which
  /// exists yet.
  damageTakenMultiplier(defaultValue: 1, minimum: 0);

  const Stat({required this.defaultValue, this.minimum = 0});

  /// Used when a unit does not specify a base for this stat.
  final double defaultValue;

  /// Floor applied *after* the whole modifier pipeline has run.
  ///
  /// A stat with a floor cannot be driven to zero or negative by stacked
  /// debuffs, which is what stops a unit acting infinitely often or being
  /// unkillable. Clamping at the end rather than per modifier means the order
  /// modifiers were applied in cannot change the result. A stat that needs a
  /// ceiling too (a crit chance, a mitigation cap) gets one the same way.
  final double minimum;

  double clamp(double value) => value < minimum ? minimum : value;
}

/// How a modifier combines with the others affecting the same stat.
///
/// The split between [increased] and [more] is the whole reason balance stays
/// predictable: a hundred small additive bonuses stay legible, while the rare
/// multiplicative one is visibly special. Two `increased` 10% bonuses give
/// +20%; two `more` 10% bonuses give +21%.
enum ModOp {
  /// `+12 attack power`. Summed with every other flat modifier.
  flat,

  /// `+10% attack power`. Summed with every other increase, applied once.
  increased,

  /// `x1.5 attack power`. Multiplied in on its own. Keep these rare —
  /// capstones and legendaries, not common gear.
  more,
}
