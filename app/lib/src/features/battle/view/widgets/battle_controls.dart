import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/combat_snapshot.dart';
import '../../../../core/events/game_event.dart';
import '../../bloc/battle_bloc.dart';
import '../../bloc/battle_state.dart';
import '../battle_palette.dart';

/// Transport controls for the fight: run it, slow it down, watch it again.
class BattleControls extends StatelessWidget {
  const BattleControls({
    required this.showTargetLines,
    required this.onToggleTargetLines,
    super.key,
  });

  final bool showTargetLines;
  final ValueChanged<bool> onToggleTargetLines;

  static const List<double> _speeds = <double>[0.5, 1, 2, 4];

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<BattleBloc, BattleState>(
        builder: (BuildContext context, BattleState state) {
          final BattleBloc bloc = context.read<BattleBloc>();

          return Container(
            color: BattlePalette.panel,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                _playButton(bloc, state.status),
                OutlinedButton.icon(
                  onPressed: () =>
                      bloc.add(const RestartBattleRequested()),
                  icon: const Icon(Icons.replay, size: 16),
                  label: const Text('Restart'),
                ),
                SegmentedButton<double>(
                  showSelectedIcon: false,
                  segments: <ButtonSegment<double>>[
                    for (final double speed in _speeds)
                      ButtonSegment<double>(
                        value: speed,
                        label: Text('${_format(speed)}x'),
                      ),
                  ],
                  selected: <double>{state.speed},
                  onSelectionChanged: (Set<double> selection) =>
                      bloc.add(SpeedChangeRequested(selection.first)),
                ),
                _targetLinesToggle(),
                Text(
                  '${state.snapshot.elapsed.toStringAsFixed(1)}s',
                  style: const TextStyle(
                    fontSize: 12,
                    color: BattlePalette.textMuted,
                  ),
                ),
              ],
            ),
          );
        },
      );

  Widget _playButton(BattleBloc bloc, BattleStatus status) => switch (status) {
        BattleStatus.notStarted => FilledButton.icon(
            onPressed: () => bloc.add(const StartBattleRequested()),
            icon: const Icon(Icons.play_arrow, size: 16),
            label: const Text('Start'),
          ),
        BattleStatus.running => FilledButton.icon(
            onPressed: () => bloc.add(const PauseBattleRequested()),
            icon: const Icon(Icons.pause, size: 16),
            label: const Text('Pause'),
          ),
        BattleStatus.paused => FilledButton.icon(
            onPressed: () => bloc.add(const ResumeBattleRequested()),
            icon: const Icon(Icons.play_arrow, size: 16),
            label: const Text('Resume'),
          ),
        BattleStatus.finished => FilledButton.icon(
            onPressed: null,
            icon: const Icon(Icons.flag, size: 16),
            label: const Text('Resolved'),
          ),
      };

  Widget _targetLinesToggle() => Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Switch(
            value: showTargetLines,
            onChanged: onToggleTargetLines,
          ),
          const Text(
            'Target lines',
            style: TextStyle(fontSize: 12, color: BattlePalette.textMuted),
          ),
        ],
      );

  static String _format(double speed) =>
      speed == speed.roundToDouble() ? speed.toStringAsFixed(0) : '$speed';
}
