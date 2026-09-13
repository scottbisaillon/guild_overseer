import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../battle/data/mock_roster.dart';
import '../../../battle/domain/arena_layout.dart';
import '../../../battle/domain/party_formation.dart';
import '../../../battle/domain/skill.dart';
import '../../../battle/domain/unit_blueprint.dart';
import '../../../battle/view/battle_palette.dart';
import '../../cubit/party_cubit.dart';
import '../../cubit/party_state.dart';
import 'blueprint_card.dart';
import 'role_glyph.dart';
import 'skill_picker.dart';
import 'unit_drag_source.dart';

/// The party's half of the arena, as somewhere to put people.
///
/// The board is the formation grid the fight is actually fought on, drawn the
/// way the battle draws it: the front line nearest the centre of the arena,
/// which is the right-hand edge here, with the enemy beyond it. A unit placed
/// in the top-right cell is the unit that will be standing there when the
/// fight starts, and the shape of the grid comes from [ArenaLayout] rather than
/// from anything this screen decided.
class FormationBoard extends StatelessWidget {
  const FormationBoard({this.layout = kArenaLayout, super.key});

  final ArenaLayout layout;

  /// Columns run front-to-back in the arena; on screen they run back-to-front,
  /// left to right, so the party faces the enemy the way it does in battle.
  List<int> get _columnsLeftToRight =>
      <int>[for (int c = layout.columns - 1; c >= 0; c--) c];

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<PartyCubit, PartyState>(
        builder: (BuildContext context, PartyState state) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _headerRow(),
            const SizedBox(height: 6),
            for (int row = 0; row < layout.rows; row++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: <Widget>[
                    for (final int column in _columnsLeftToRight) ...<Widget>[
                      Expanded(
                        child: _FormationCell(
                          // Keyed by the slot it draws, so a cell keeps its
                          // identity as the formation around it changes.
                          key: ValueKey<FormationSlot>(
                            (row: row, column: column),
                          ),
                          slot: (row: row, column: column),
                          state: state,
                        ),
                      ),
                      if (column != 0) const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
          ],
        ),
      );

  Widget _headerRow() => Row(
        children: <Widget>[
          for (final int column in _columnsLeftToRight) ...<Widget>[
            Expanded(
              child: Text(
                _columnLabel(column),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  letterSpacing: 2,
                  color: BattlePalette.textMuted,
                ),
              ),
            ),
            if (column != 0) const SizedBox(width: 8),
          ],
        ],
      );

  String _columnLabel(int column) {
    if (column == 0) {
      return 'FRONT LINE';
    }
    return column == layout.columns - 1 ? 'BACK LINE' : 'LINE ${column + 1}';
  }
}

/// One cell: a place to drop a unit, and a place to tap one down.
///
/// Both gestures end in the same place. A drop hands the cell the unit it is
/// carrying; a tap hands it whatever the player is holding, or picks up the
/// unit standing here when they are holding nothing.
class _FormationCell extends StatelessWidget {
  const _FormationCell({required this.slot, required this.state, super.key});

  final FormationSlot slot;
  final PartyState state;

  static const double _height = 62;

  @override
  Widget build(BuildContext context) {
    final PartyCubit cubit = context.read<PartyCubit>();
    final String? unitId = state.formation.at(slot);
    final UnitBlueprint? authored =
        unitId == null ? null : recruitableUnit(unitId);
    // Drawn as the player has it: a unit standing on the board shows the
    // skills it is taking, not the ones it came with.
    final UnitBlueprint? unit =
        authored == null ? null : unitWithSkills(authored, state.skills);

    return DragTarget<String>(
      onAcceptWithDetails: (DragTargetDetails<String> details) =>
          cubit.dropOnSlot(details.data, slot),
      builder: (
        BuildContext context,
        List<String?> candidates,
        List<dynamic> rejected,
      ) {
        final bool hovered = candidates.isNotEmpty;
        // A held unit turns every cell into somewhere to put it, and saying so
        // is the only thing that makes select-and-place discoverable.
        final bool inviting = hovered || state.heldUnitId != null;
        final bool held = unitId != null && state.isHeld(unitId);

        return SizedBox(
          height: _height,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => cubit.tapSlot(slot),
              child: Container(
                decoration: BoxDecoration(
                  color: hovered
                      ? BattlePalette.ally.withValues(alpha: 0.14)
                      : BattlePalette.arenaFloor,
                  border: Border.all(
                    color: hovered || held
                        ? BattlePalette.ally
                        : inviting
                            ? BattlePalette.centreLine
                            : BattlePalette.gridLine,
                  ),
                ),
                child: unit == null || authored == null
                    ? _empty(inviting)
                    // The picker is opened on the unit as authored: what it is
                    // carrying now comes from the cubit, and resetting has to
                    // have somewhere to reset to.
                    : _PlacedUnit(
                        blueprint: unit,
                        held: held,
                        onEditSkills: () => showSkillPicker(context, authored),
                        onRemove: () => cubit.clearSlot(slot),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _empty(bool inviting) => Center(
        child: Text(
          inviting ? 'PLACE HERE' : 'EMPTY',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 2,
            color: inviting ? BattlePalette.ally : BattlePalette.dead,
          ),
        ),
      );
}

/// A unit standing in a cell: who it is, what it is bringing, and the two ways
/// back out — drag it somewhere else, or take it off the board entirely.
class _PlacedUnit extends StatelessWidget {
  const _PlacedUnit({
    required this.blueprint,
    required this.held,
    required this.onEditSkills,
    required this.onRemove,
  });

  final UnitBlueprint blueprint;
  final bool held;
  final VoidCallback onEditSkills;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => UnitDragSource(
        unitId: blueprint.id,
        feedback: SizedBox(
          width: 200,
          child: BlueprintCard(blueprint: blueprint),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: <Widget>[
              RoleGlyph(role: blueprint.role),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      blueprint.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: held
                            ? BattlePalette.ally
                            : BattlePalette.textPrimary,
                      ),
                    ),
                    Text(
                      '${blueprint.maxHealth.toStringAsFixed(0)} hp  ·  '
                      '${_rotation(blueprint)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: BattlePalette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onEditSkills,
                visualDensity: VisualDensity.compact,
                iconSize: 16,
                tooltip: 'Skills for ${blueprint.name}',
                icon: const Icon(Icons.bolt, color: BattlePalette.textMuted),
              ),
              IconButton(
                onPressed: onRemove,
                visualDensity: VisualDensity.compact,
                iconSize: 16,
                tooltip: 'Remove ${blueprint.name}',
                icon: const Icon(Icons.close, color: BattlePalette.textMuted),
              ),
            ],
          ),
        ),
      );

  /// What this unit will fire, in the order it will try to: the line that makes
  /// a customised unit readable off the board.
  String _rotation(UnitBlueprint unit) =>
      unit.skills.map((SkillDefinition skill) => skill.name).join(', ');
}
