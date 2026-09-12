import 'dart:math' as math;

import '../../../core/domain/faction.dart';


/// A point in arena space. Arena space is resolution independent — the renderer
/// scales it to whatever the window happens to be.
typedef ArenaPoint = ({double x, double y});

/// The arena every part of the app measures against.
const ArenaLayout kArenaLayout = ArenaLayout();

/// Where every formation slot sits in the arena.
///
/// Both factions use the same grid shape, mirrored across the centre line, so
/// column 0 is always the front line and column 1 is always the back line no
/// matter which side you are on. Targeting rules like "frontline first" then
/// mean the same thing for both sides.
class ArenaLayout {
  const ArenaLayout({
    this.width = 1280,
    this.height = 720,
    this.rows = 3,
    this.columns = 2,
    this.cellSize = 96,
    this.cellGap = 38,
    this.centreGap = 260,
  });

  final double width;
  final double height;

  /// Slots from top to bottom in one formation.
  final int rows;

  /// Slots from the centre line outward: 0 is the front line.
  final int columns;

  final double cellSize;

  /// Space between adjacent cells of the same formation. Wide enough that the
  /// name under one unit clears the health bar over the unit below it.
  final double cellGap;

  /// Space between the two front lines, across the centre of the arena.
  final double centreGap;

  double get centreX => width / 2;

  double get centreY => height / 2;

  int get slotsPerSide => rows * columns;

  /// Centre of the cell at [row]/[column] for [faction], in arena space.
  ArenaPoint slotCentre(Faction faction, int row, int column) {
    final double offsetFromCentre =
        centreGap / 2 + cellSize / 2 + column * (cellSize + cellGap);
    final double x = faction == Faction.ally
        ? centreX - offsetFromCentre
        : centreX + offsetFromCentre;
    final double y =
        centreY + (row - (rows - 1) / 2) * (cellSize + cellGap);
    return (x: x, y: y);
  }

  /// Squared distance between two slots.
  ///
  /// Squared, because ordering is all any caller needs and square roots are not
  /// free when this runs for every unit against every opponent each frame.
  double distanceSquared(
    Faction aFaction,
    int aRow,
    int aColumn,
    Faction bFaction,
    int bRow,
    int bColumn,
  ) {
    final ArenaPoint a = slotCentre(aFaction, aRow, aColumn);
    final ArenaPoint b = slotCentre(bFaction, bRow, bColumn);
    final double dx = a.x - b.x;
    final double dy = a.y - b.y;
    return dx * dx + dy * dy;
  }

  /// Straight-line distance between two slots.
  double distance(
    Faction aFaction,
    int aRow,
    int aColumn,
    Faction bFaction,
    int bRow,
    int bColumn,
  ) =>
      math.sqrt(
        distanceSquared(aFaction, aRow, aColumn, bFaction, bRow, bColumn),
      );
}
