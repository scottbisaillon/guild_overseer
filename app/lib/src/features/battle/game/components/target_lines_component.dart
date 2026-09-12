import 'dart:ui';

import 'package:flame/components.dart';

import '../../domain/arena_layout.dart';
import '../../domain/battle_simulation.dart';
import '../../domain/combatant.dart';
import '../../view/battle_palette.dart';
import '../battle_game.dart';

/// A faint line from every living unit to whoever it is currently attacking.
///
/// This is the debug-inspection view made permanent: targeting is the least
/// visible part of the fight and the easiest to get wrong, so it gets to be
/// looked at directly. Toggleable from the HUD.
class TargetLinesComponent extends PositionComponent
    with HasGameReference<BattleGame> {
  TargetLinesComponent({required this.simulation, required this.layout})
      : super(
          size: Vector2(layout.width, layout.height),
          priority: 10,
        );

  final BattleSimulation simulation;
  final ArenaLayout layout;

  @override
  void render(Canvas canvas) {
    if (!game.showTargetLines) {
      return;
    }
    for (final Combatant unit in simulation.units) {
      if (!unit.isAlive) {
        continue;
      }
      final Combatant? target = simulation.unitById(unit.targetId);
      if (target == null || !target.isAlive) {
        continue;
      }
      final ArenaPoint from = unit.position(layout);
      final ArenaPoint to = target.position(layout);
      canvas.drawLine(
        Offset(from.x, from.y),
        Offset(to.x, to.y),
        Paint()
          ..color = BattlePalette.faction(unit.faction).withValues(alpha: 0.16)
          ..strokeWidth = 1.5,
      );
    }
  }
}
