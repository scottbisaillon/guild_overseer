import 'package:flutter/material.dart';

import '../../../core/domain/combat_role.dart';
import '../../../core/domain/faction.dart';

/// The one place colours are decided.
///
/// Both the Flame canvas and the Flutter HUD read from here, so a unit's blue
/// on the battlefield is the same blue on its roster card.
abstract final class BattlePalette {
  static const Color background = Color(0xFF0F1017);
  static const Color arenaFloor = Color(0xFF171A24);
  static const Color panel = Color(0xFF14161F);
  static const Color gridLine = Color(0xFF262A38);
  static const Color centreLine = Color(0xFF323849);

  static const Color ally = Color(0xFF4F9BD1);
  static const Color enemy = Color(0xFFD1564F);

  static const Color textPrimary = Color(0xFFE4E7F0);
  static const Color textMuted = Color(0xFF868DA6);

  static const Color damage = Color(0xFFFF7A6B);
  static const Color heal = Color(0xFF6BE2A8);
  static const Color dead = Color(0xFF4A4F63);

  static Color faction(Faction faction) =>
      faction == Faction.ally ? ally : enemy;

  /// Role accent, shared by the stripe on a unit and the badge on its card.
  static Color role(CombatRole role) => switch (role) {
        CombatRole.tank => const Color(0xFF9AA5C4),
        CombatRole.meleeDps => const Color(0xFFE0A33B),
        CombatRole.rangedDps => const Color(0xFF8ED17F),
        CombatRole.healer => const Color(0xFF7ED9C4),
        CombatRole.support => const Color(0xFFB78FD9),
      };
}
