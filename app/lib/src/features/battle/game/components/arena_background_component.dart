import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' show FontWeight, TextStyle;

import '../../../../core/domain/faction.dart';
import '../../domain/arena_layout.dart';
import '../../view/battle_palette.dart';

/// The arena floor, the centre line, and the two empty formation grids.
///
/// Drawn once per frame underneath everything else. It renders the grid from
/// the layout rather than from the roster, so empty slots stay visible when a
/// unit dies.
class ArenaBackgroundComponent extends PositionComponent {
  ArenaBackgroundComponent({required this.layout})
      : super(
          size: Vector2(layout.width, layout.height),
          priority: 0,
        );

  final ArenaLayout layout;

  static final Paint _floorPaint = Paint()..color = BattlePalette.arenaFloor;
  static final Paint _cellPaint = Paint()
    ..color = BattlePalette.gridLine
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  static final Paint _centrePaint = Paint()
    ..color = BattlePalette.centreLine
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  static final TextPaint _labelPaint = TextPaint(
    style: const TextStyle(
      color: BattlePalette.textMuted,
      fontSize: 16,
      letterSpacing: 4,
      fontWeight: FontWeight.w600,
    ),
  );

  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), _floorPaint);

    for (final Faction faction in Faction.values) {
      for (int row = 0; row < layout.rows; row++) {
        for (int column = 0; column < layout.columns; column++) {
          final ArenaPoint centre = layout.slotCentre(faction, row, column);
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset(centre.x, centre.y),
              width: layout.cellSize,
              height: layout.cellSize,
            ),
            _cellPaint,
          );
        }
      }
    }

    // The centre line the two formations face across. Dashed, so it reads as a
    // boundary rather than a wall.
    const double dash = 14;
    for (double y = 40; y < layout.height - 40; y += dash * 2) {
      canvas.drawLine(
        Offset(layout.centreX, y),
        Offset(layout.centreX, y + dash),
        _centrePaint,
      );
    }

    _labelPaint.render(
      canvas,
      'ALLIES',
      Vector2(layout.centreX - 40, 32),
      anchor: Anchor.topRight,
    );
    _labelPaint.render(
      canvas,
      'ENEMIES',
      Vector2(layout.centreX + 40, 32),
      anchor: Anchor.topLeft,
    );
  }
}
