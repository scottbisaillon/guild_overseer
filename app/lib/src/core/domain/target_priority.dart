import 'combat_role.dart';
import 'target_selector.dart';

/// How a unit chooses which opponent to attack.
///
/// The player-facing vocabulary: six named presets over [TargetSelector],
/// which is what actually decides. Each is a [selector] with a different
/// ranking, so a priority and a skill's targeting are resolved by the same
/// code — there is no second scoring path to keep in step with the first.
///
/// The priority is evaluated once and cached on the unit until the chosen
/// target becomes invalid (dies or leaves the fight) — re-evaluating every
/// frame thrashes targets and makes behaviour unreadable.
enum TargetPriority {
  /// Closest opponent by world distance. The default for melee.
  nearest('Nearest', TargetOrder.nearest),

  /// Opponent with the lowest health percentage. Prioritises finishing kills.
  weakest('Weakest', TargetOrder.lowestHealthFraction),

  /// Opponent with the highest maximum health. Niche, used by boss-like units.
  strongest('Strongest', TargetOrder.highestMaxHealth),

  /// Opponents in the column closest to the centre line first.
  frontline('Frontline', TargetOrder.frontline),

  /// Opponents in the column furthest from the centre line first.
  backline('Backline', TargetOrder.backline),

  /// Enemy healers first, then nearest. Mirrors the Debuffer archetype.
  healerFirst(
    'Healer first',
    TargetOrder.preferredRole,
    preferredRole: CombatRole.healer,
  );

  const TargetPriority(this.label, this.order, {this.preferredRole});

  /// Human readable name used by the HUD.
  final String label;

  /// How this priority ranks the opposing side.
  final TargetOrder order;

  /// The role this priority hunts before falling back to distance, if any.
  final CombatRole? preferredRole;

  /// This priority as the thing that actually resolves it: one opponent,
  /// ranked across the whole opposing side, distance settling ties.
  TargetSelector get selector => TargetSelector(
        side: TargetSide.enemies,
        order: order,
        preferredRole: preferredRole,
      );
}
