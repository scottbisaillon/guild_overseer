/// The job a combatant performs in a fight.
///
/// A role is a bundle of defaults — how it picks targets, how far it reaches —
/// that individual units may override. It is deliberately independent of the
/// class system: a class picks a role, it is not a role.
enum CombatRole {
  tank('Tank', 'T'),
  meleeDps('Melee DPS', 'M'),
  rangedDps('Ranged DPS', 'R'),
  healer('Healer', 'H'),
  support('Support', 'S');

  const CombatRole(this.label, this.glyph);

  /// Human readable name used by the HUD.
  final String label;

  /// Single character drawn on the unit in the arena.
  final String glyph;
}
