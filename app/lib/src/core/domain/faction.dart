/// Which side of a fight a combatant belongs to.
///
/// Faction is data carried by a unit, never a subclass. Adding a third side
/// (neutral, hostile-to-all, temporarily allied) is adding a value here, not
/// restructuring the type hierarchy.
enum Faction {
  ally('Allies'),
  enemy('Enemies');

  const Faction(this.label);

  /// Human readable name used by the HUD.
  final String label;

  /// The side this faction fights.
  Faction get opposing => switch (this) {
        Faction.ally => Faction.enemy,
        Faction.enemy => Faction.ally,
      };
}
