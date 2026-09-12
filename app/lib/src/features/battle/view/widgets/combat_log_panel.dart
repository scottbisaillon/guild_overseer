import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/battle_bloc.dart';
import '../../bloc/battle_state.dart';
import '../battle_palette.dart';

/// The running record of what the simulation decided, newest at the bottom.
///
/// Every line is a `GameEvent` the simulation published — the log is not
/// assembled by the UI, it is the event stream made readable.
class CombatLogPanel extends StatelessWidget {
  const CombatLogPanel({super.key});

  @override
  Widget build(BuildContext context) => Container(
        color: BattlePalette.panel,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.fromLTRB(10, 8, 10, 4),
              child: Text(
                'COMBAT LOG',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w700,
                  color: BattlePalette.textMuted,
                ),
              ),
            ),
            Expanded(
              child: BlocBuilder<BattleBloc, BattleState>(
                buildWhen: (BattleState previous, BattleState current) =>
                    previous.log != current.log,
                builder: (BuildContext context, BattleState state) {
                  final List<CombatLogEntry> log = state.log;
                  if (log.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'waiting for the first beat…',
                        style: TextStyle(
                          fontSize: 11,
                          color: BattlePalette.dead,
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    // Reversed so the newest line sits at the bottom and the
                    // view stays pinned there as the fight runs.
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                    itemCount: log.length,
                    itemBuilder: (BuildContext context, int index) =>
                        _LogLine(entry: log[log.length - 1 - index]),
                  );
                },
              ),
            ),
          ],
        ),
      );
}

class _LogLine extends StatelessWidget {
  const _LogLine({required this.entry});

  final CombatLogEntry entry;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: 44,
              child: Text(
                entry.at.toStringAsFixed(1).padLeft(5),
                style: const TextStyle(
                  fontSize: 11,
                  color: BattlePalette.dead,
                ),
              ),
            ),
            Expanded(
              child: Text(
                entry.text,
                style: TextStyle(fontSize: 11, color: _colorFor(entry.kind)),
              ),
            ),
          ],
        ),
      );

  static Color _colorFor(CombatLogKind kind) => switch (kind) {
        CombatLogKind.damage => BattlePalette.textPrimary,
        CombatLogKind.heal => BattlePalette.heal,
        CombatLogKind.death => BattlePalette.damage,
        CombatLogKind.targeting => BattlePalette.textMuted,
        CombatLogKind.system => BattlePalette.ally,
      };
}
