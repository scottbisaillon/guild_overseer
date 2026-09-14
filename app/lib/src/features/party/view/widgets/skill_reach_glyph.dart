import 'package:flutter/material.dart';

import '../../../../core/domain/faction.dart';
import '../../../battle/domain/arena_layout.dart';
import '../../../battle/domain/party_formation.dart';
import '../../../battle/domain/skill_reach.dart';
import '../../../battle/view/battle_palette.dart';

/// The arena in miniature, with the cells a skill lands on lit up.
///
/// Choosing a skill out of a list of names asks the player to know that Cleave
/// takes a rank and Volley takes a row. This says it instead: the same two
/// formations the fight is resolved on, a few pixels wide, with the ground the
/// skill covers filled in — a tall block for a rank, a wide one for a row, a
/// whole side for a storm.
///
/// It is the same picture the battle draws when the blow lands, which is the
/// point: what you picked is what you will see.
class SkillReachGlyph extends StatelessWidget {
  const SkillReachGlyph({
    required this.reach,
    this.layout = kArenaLayout,
    this.cell = 6,
    this.gap = 2,
    super.key,
  });

  final SkillReach reach;
  final ArenaLayout layout;

  /// Side of one cell, and the space between two of them.
  final double cell;
  final double gap;

  /// The gap down the middle, where the two sides face each other.
  double get _centreGap => cell * 1.6;

  double get _width =>
      2 * (layout.columns * cell + (layout.columns - 1) * gap) + _centreGap;

  double get _height => layout.rows * cell + (layout.rows - 1) * gap;

  @override
  Widget build(BuildContext context) => Semantics(
        label: _description(),
        child: SizedBox(
          width: _width,
          height: _height,
          child: CustomPaint(
            painter: _ReachPainter(reach: reach, layout: layout, gap: gap),
          ),
        ),
      );

  /// What the glyph says, for anyone who cannot see it.
  String _description() {
    final int allies = reach.allies.length;
    final int enemies = reach.enemies.length;
    if (allies == 0 && enemies == 0) {
      return 'Lands on nobody';
    }
    final List<String> parts = <String>[
      if (enemies > 0) '$enemies enemy ${enemies == 1 ? 'cell' : 'cells'}',
      if (allies > 0) '$allies friendly ${allies == 1 ? 'cell' : 'cells'}',
    ];
    return 'Lands on ${parts.join(' and ')}';
  }
}

/// Draws the two formations, allies on the left as the arena draws them, each
/// side's front line nearest the middle.
class _ReachPainter extends CustomPainter {
  const _ReachPainter({
    required this.reach,
    required this.layout,
    required this.gap,
  });

  final SkillReach reach;
  final ArenaLayout layout;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final double cell =
        (size.height - (layout.rows - 1) * gap) / layout.rows;
    final double centreGap = cell * 1.6;
    final double centreX = size.width / 2;

    for (final Faction faction in Faction.values) {
      for (final FormationSlot slot in PartyFormation.slots(layout: layout)) {
        _paintCell(
          canvas,
          _rectFor(
            faction: faction,
            slot: slot,
            cell: cell,
            centreX: centreX,
            centreGap: centreGap,
          ),
          faction,
          slot,
        );
      }
    }
  }

  /// Where a cell sits. Column 0 is the front line, so it is drawn nearest the
  /// middle on both sides: the ally grid runs outward to the left, the enemy
  /// grid outward to the right, exactly as the arena stands them.
  Rect _rectFor({
    required Faction faction,
    required FormationSlot slot,
    required double cell,
    required double centreX,
    required double centreGap,
  }) {
    final double fromCentre = centreGap / 2 + slot.column * (cell + gap);
    final double left = faction == Faction.ally
        ? centreX - fromCentre - cell
        : centreX + fromCentre;
    return Rect.fromLTWH(left, slot.row * (cell + gap), cell, cell);
  }

  void _paintCell(
    Canvas canvas,
    Rect rect,
    Faction faction,
    FormationSlot slot,
  ) {
    final bool covered = reach.covers(faction, slot);
    final Color color = faction == Faction.ally
        ? BattlePalette.ally
        : BattlePalette.enemy;

    canvas.drawRect(
      rect,
      Paint()
        ..color = covered
            ? color
            : BattlePalette.gridLine.withValues(alpha: 0.55),
    );

    // Where the blow comes from, marked even when it lands somewhere else.
    if (faction == Faction.ally && slot == reach.caster && !covered) {
      canvas.drawRect(
        rect.deflate(0.5),
        Paint()
          ..color = BattlePalette.textMuted
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(_ReachPainter oldDelegate) =>
      oldDelegate.reach != reach || oldDelegate.layout != layout;
}
