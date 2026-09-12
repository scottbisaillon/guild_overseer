/// What a skill does when it resolves.
enum SkillKind { damage, heal }

/// How a skill reaches its target — purely presentational, but decided by the
/// skill definition so the renderer never has to guess from the unit's role.
enum SkillDelivery {
  /// The unit lunges at its target and snaps back to its slot.
  melee,

  /// A projectile travels from the caster to the target.
  projectile,

  /// A beam is drawn between caster and target for a moment.
  beam,
}
