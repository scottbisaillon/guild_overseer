import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/combat_snapshot.dart';
import '../../../../core/domain/faction.dart';
import '../../bloc/battle_bloc.dart';
import '../../bloc/battle_state.dart';
import '../battle_palette.dart';
import 'unit_card.dart';

/// One side's roster, stacked to mirror its formation on the battlefield.
class RosterPanel extends StatelessWidget {
  const RosterPanel({required this.faction, this.width = 260, super.key});

  final Faction faction;
  final double width;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<BattleBloc, BattleState>(
        builder: (BuildContext context, BattleState state) {
          final List<UnitSnapshot> units = state.unitsOf(faction);
          final int alive = units.where((UnitSnapshot u) => u.isAlive).length;

          return SizedBox(
            width: width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _RosterHeader(
                  faction: faction,
                  alive: alive,
                  total: units.length,
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: units.length,
                    separatorBuilder: (BuildContext context, int index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (BuildContext context, int index) =>
                        UnitCard(unit: units[index]),
                  ),
                ),
              ],
            ),
          );
        },
      );
}

/// The same roster as a horizontal strip, for phone-width layouts.
class RosterStrip extends StatelessWidget {
  const RosterStrip({required this.faction, super.key});

  final Faction faction;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<BattleBloc, BattleState>(
        builder: (BuildContext context, BattleState state) {
          final List<UnitSnapshot> units = state.unitsOf(faction);
          return SizedBox(
            height: 62,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              itemCount: units.length,
              separatorBuilder: (BuildContext context, int index) =>
                  const SizedBox(width: 6),
              itemBuilder: (BuildContext context, int index) => SizedBox(
                width: 150,
                child: UnitCard(unit: units[index], compact: true),
              ),
            ),
          );
        },
      );
}

class _RosterHeader extends StatelessWidget {
  const _RosterHeader({
    required this.faction,
    required this.alive,
    required this.total,
  });

  final Faction faction;
  final int alive;
  final int total;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        color: BattlePalette.panel,
        child: Row(
          children: <Widget>[
            Container(
              width: 10,
              height: 10,
              color: BattlePalette.faction(faction),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                faction.label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w700,
                  color: BattlePalette.textPrimary,
                ),
              ),
            ),
            Text(
              '$alive/$total',
              style: const TextStyle(
                fontSize: 11,
                color: BattlePalette.textMuted,
              ),
            ),
          ],
        ),
      );
}
