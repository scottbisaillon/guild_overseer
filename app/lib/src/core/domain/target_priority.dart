import 'combat_role.dart';

/// How a unit chooses which opponent to attack.
///
/// The priority is evaluated once and cached on the unit until the chosen
/// target becomes invalid (dies or leaves the fight) — re-evaluating every
/// frame thrashes targets and makes behaviour unreadable.
enum TargetPriority {
  /// Closest opponent by world distance. The default for melee.
  nearest('Nearest'),

  /// Opponent with the lowest health percentage. Prioritises finishing kills.
  weakest('Weakest'),

  /// Opponent with the highest maximum health. Niche, used by boss-like units.
  strongest('Strongest'),

  /// Opponents in the column closest to the centre line first.
  frontline('Frontline'),

  /// Opponents in the column furthest from the centre line first.
  backline('Backline'),

  /// Enemy healers first, then nearest. Mirrors the Debuffer archetype.
  healerFirst('Healer first');

  const TargetPriority(this.label);

  /// Human readable name used by the HUD.
  final String label;

  /// The role this priority hunts before falling back to distance, if any.
  CombatRole? get preferredRole =>
      this == TargetPriority.healerFirst ? CombatRole.healer : null;
}
