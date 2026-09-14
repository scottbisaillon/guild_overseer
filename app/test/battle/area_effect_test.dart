import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:guild_overseer/src/core/domain/faction.dart';
import 'package:guild_overseer/src/features/battle/domain/arena_layout.dart';
import 'package:guild_overseer/src/features/battle/game/components/area_effect_component.dart';

/// What an area effect covers is the ground its targets are standing on, so the
/// shape it draws is the shape the skill hit. These check that without a game:
/// the footprint is a function of the cells, and nothing else.
void main() {
  const ArenaLayout layout = kArenaLayout;

  Rect cell(int row, int column, {Faction faction = Faction.enemy}) {
    final ArenaPoint centre = layout.slotCentre(faction, row, column);
    return Rect.fromCenter(
      center: Offset(centre.x, centre.y),
      width: layout.cellSize,
      height: layout.cellSize,
    );
  }

  test('a rank comes out taller than it is wide', () {
    final Rect area = coveredArea(<Rect>[
      cell(0, 0),
      cell(1, 0),
      cell(2, 0),
    ]);

    expect(area.height, greaterThan(area.width));
    // Three cells and the two gaps between them, plus the padding either end.
    expect(
      area.height,
      closeTo(3 * layout.cellSize + 2 * layout.cellGap + 20, 0.001),
    );
  });

  test('a row comes out wider than it is tall', () {
    final Rect area = coveredArea(<Rect>[cell(1, 0), cell(1, 1)]);

    expect(area.width, greaterThan(area.height));
    expect(area.height, closeTo(layout.cellSize + 20, 0.001));
  });

  test('a whole side covers every cell of it', () {
    final Rect area = coveredArea(<Rect>[
      for (int row = 0; row < layout.rows; row++)
        for (int column = 0; column < layout.columns; column++)
          cell(row, column),
    ]);

    for (int row = 0; row < layout.rows; row++) {
      for (int column = 0; column < layout.columns; column++) {
        expect(area.contains(cell(row, column).center), isTrue);
      }
    }
    // The other side is somebody else's ground.
    expect(area.contains(cell(0, 0, faction: Faction.ally).center), isFalse);
  });

  test('one cell is that cell, with air around it', () {
    final Rect area = coveredArea(<Rect>[cell(0, 0)], padding: 4);

    expect(area.width, closeTo(layout.cellSize + 8, 0.001));
    expect(area.center, cell(0, 0).center);
  });

  test('no cells is no ground, rather than a footprint at the origin', () {
    expect(coveredArea(const <Rect>[]), Rect.zero);
  });
}
