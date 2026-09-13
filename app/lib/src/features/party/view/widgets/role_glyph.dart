import 'package:flutter/material.dart';

import '../../../../core/domain/combat_role.dart';
import '../../../battle/view/battle_palette.dart';

/// A unit's role as the single character the arena draws on it.
///
/// The same glyph in the same colour on the bench, in a formation cell and on
/// the battlefield, so a party recognised here is recognisable there.
class RoleGlyph extends StatelessWidget {
  const RoleGlyph({required this.role, this.size = 20, super.key});

  final CombatRole role;
  final double size;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: role.label,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          color: BattlePalette.role(role),
          child: Text(
            role.glyph,
            style: TextStyle(
              fontSize: size * 0.6,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0B0D14),
            ),
          ),
        ),
      );
}
