import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../battle/data/mock_roster.dart';
import '../../../battle/domain/arena_layout.dart';
import '../../../battle/domain/unit_blueprint.dart';
import '../../../battle/view/battle_palette.dart';
import '../../cubit/party_cubit.dart';
import '../../cubit/party_state.dart';
import 'blueprint_card.dart';
import 'unit_drag_source.dart';

/// Everybody the player can take, and where a unit goes when it is taken back
/// off the board.
///
/// The bench is a drop target as well as a source: dragging a placed unit onto
/// it is how you change your mind, and it means a unit dropped somewhere
/// meaningless has an obvious place to have come from.
class UnitBench extends StatelessWidget {
  const UnitBench({
    this.units = kRecruitableUnits,
    this.layout = kArenaLayout,
    super.key,
  });

  final List<UnitBlueprint> units;

  /// Read for the slot count it reports. Nothing is enforced here — the board
  /// enforces it by having nowhere else to put anybody.
  final ArenaLayout layout;

  @override
  Widget build(BuildContext context) {
    final PartyCubit cubit = context.read<PartyCubit>();

    return BlocBuilder<PartyCubit, PartyState>(
      builder: (BuildContext context, PartyState state) => DragTarget<String>(
        onAcceptWithDetails: (DragTargetDetails<String> details) =>
            cubit.bench(details.data),
        builder: (
          BuildContext context,
          List<String?> candidates,
          List<dynamic> rejected,
        ) {
          final bool hovered = candidates.isNotEmpty;

          return ColoredBox(
            color: hovered ? BattlePalette.panel : BattlePalette.background,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _header(state, hovered),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: units.length,
                    separatorBuilder: (BuildContext context, int index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (BuildContext context, int index) =>
                        _benchEntry(cubit, state, units[index]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// One unit: tappable to pick up, draggable to carry, and the same card
  /// either way.
  Widget _benchEntry(PartyCubit cubit, PartyState state, UnitBlueprint unit) {
    final Widget card = BlueprintCard(
      blueprint: unit,
      held: state.isHeld(unit.id),
      placed: state.isPlaced(unit.id),
      onTap: () => cubit.tapUnit(unit.id),
    );
    return UnitDragSource(
      unitId: unit.id,
      feedback: SizedBox(width: 220, child: card),
      child: card,
    );
  }

  Widget _header(PartyState state, bool hovered) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        color: BattlePalette.panel,
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                hovered ? 'DROP TO REMOVE' : 'AVAILABLE UNITS',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w700,
                  color:
                      hovered ? BattlePalette.ally : BattlePalette.textPrimary,
                ),
              ),
            ),
            Text(
              '${state.placedCount}/${layout.slotsPerSide}',
              style: const TextStyle(
                fontSize: 11,
                color: BattlePalette.textMuted,
              ),
            ),
          ],
        ),
      );
}
