import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/combat_snapshot.dart';
import '../../../../core/domain/faction.dart';
import '../../../../core/events/game_event.dart';
import '../../bloc/battle_bloc.dart';
import '../../bloc/battle_state.dart';
import '../battle_palette.dart';

/// Shown over the arena once one side is wiped.
class BattleResultBanner extends StatelessWidget {
  const BattleResultBanner({required this.state, super.key});

  final BattleState state;

  @override
  Widget build(BuildContext context) {
    final Faction? winner = state.winner;
    if (winner == null) {
      return const SizedBox.shrink();
    }
    final int survivors = state
        .unitsOf(winner)
        .where((UnitSnapshot u) => u.isAlive)
        .length;

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        decoration: BoxDecoration(
          color: BattlePalette.panel,
          border: Border.all(color: BattlePalette.faction(winner), width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              '${winner.label.toUpperCase()} WIN',
              style: TextStyle(
                fontSize: 20,
                letterSpacing: 5,
                fontWeight: FontWeight.w700,
                color: BattlePalette.faction(winner),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$survivors standing · ${state.snapshot.elapsed.toStringAsFixed(1)}s',
              style: const TextStyle(
                fontSize: 12,
                color: BattlePalette.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () =>
                  context.read<BattleBloc>().add(const RestartBattleRequested()),
              icon: const Icon(Icons.replay, size: 16),
              label: const Text('Fight again'),
            ),
          ],
        ),
      ),
    );
  }
}
