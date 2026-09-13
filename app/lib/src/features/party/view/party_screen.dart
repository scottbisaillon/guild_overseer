import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../battle/data/mock_roster.dart';
import '../../battle/domain/arena_layout.dart';
import '../../battle/domain/party_formation.dart';
import '../../battle/view/battle_palette.dart';
import '../../battle/view/battle_screen.dart';
import '../cubit/party_cubit.dart';
import '../cubit/party_state.dart';
import 'widgets/formation_board.dart';
import 'widgets/unit_bench.dart';

/// Pick who fights and where they stand, then start the fight.
///
/// Two ways to place a unit, because the two pointers want different things: a
/// tap picks a unit up and a second tap puts it down, which is the only thing
/// that works one-handed on a phone; a drag carries it across, which is what a
/// mouse expects. They are the same two operations on the same formation —
/// see [PartyCubit] — so neither is a special case of the other.
///
/// Skills are fixed for now. When skill selection lands it belongs here, on
/// the unit that is being placed, rather than on a screen of its own.
class PartyScreen extends StatelessWidget {
  const PartyScreen({this.initialParty, super.key});

  static const String routePath = '/party';

  /// A party to open with, from a link that carries one. Null starts empty.
  final PartyFormation? initialParty;

  /// Below this width the bench stops fitting beside the board.
  static const double _wideLayoutBreakpoint = 900;

  /// Most of a narrow screen the board may take before it starts scrolling.
  static const double _boardShareWhenNarrow = 0.6;

  @override
  Widget build(BuildContext context) => BlocProvider<PartyCubit>(
        create: (BuildContext context) => PartyCubit(formation: initialParty),
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/'),
            ),
            title: const Text(
              'PARTY SELECT',
              style: TextStyle(fontSize: 14, letterSpacing: 4),
            ),
          ),
          body: Column(
            children: <Widget>[
              const _Instructions(),
              const Divider(height: 1),
              Expanded(
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) =>
                      constraints.maxWidth >= _wideLayoutBreakpoint
                          ? _wideLayout()
                          : _narrowLayout(),
                ),
              ),
              const Divider(height: 1),
              const _DispatchBar(),
            ],
          ),
        ),
      );

  Widget _wideLayout() => Row(
        children: <Widget>[
          const SizedBox(width: 300, child: UnitBench()),
          const VerticalDivider(width: 1),
          const Expanded(child: _BoardArea()),
        ],
      );

  /// The board keeps the top of a narrow screen: it is the thing being built,
  /// and scrolling it away to reach the bench would hide the target of every
  /// gesture on this screen. It is capped rather than given its natural
  /// height, so a short window splits between the two instead of pushing the
  /// bench off the bottom; the board scrolls inside whatever it is given.
  Widget _narrowLayout() => LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) => Column(
          children: <Widget>[
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: constraints.maxHeight * _boardShareWhenNarrow,
              ),
              child: const _BoardArea(),
            ),
            const Divider(height: 1),
            const Expanded(child: UnitBench()),
          ],
        ),
      );
}

/// How to use the screen, in one line, because a board of empty cells does not
/// say which of the two gestures it wants.
class _Instructions extends StatelessWidget {
  const _Instructions();

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<PartyCubit, PartyState>(
        builder: (BuildContext context, PartyState state) {
          final String? held = state.heldUnitId;
          final String message = held == null
              ? 'Tap a unit to pick it up, then tap a slot — or drag it across.'
              : 'Carrying ${recruitableUnit(held)?.name ?? held}. '
                  'Tap a slot to place, or tap them again to put them down.';

          return Container(
            width: double.infinity,
            color: BattlePalette.panel,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: held == null
                    ? BattlePalette.textMuted
                    : BattlePalette.ally,
              ),
            ),
          );
        },
      );
}

/// The formation, captioned so the arena's geometry is readable off the board:
/// the front line is the one the enemy reaches first.
class _BoardArea extends StatelessWidget {
  const _BoardArea();

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  'YOUR FORMATION',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w700,
                    color: BattlePalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                const FormationBoard(),
                const SizedBox(height: 4),
                const Text(
                  'enemies engage from this side  ->',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1,
                    color: BattlePalette.enemy,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

/// What the party adds up to, and the ways out of the screen.
class _DispatchBar extends StatelessWidget {
  const _DispatchBar();

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<PartyCubit, PartyState>(
        builder: (BuildContext context, PartyState state) {
          final PartyCubit cubit = context.read<PartyCubit>();
          final int slots = kArenaLayout.slotsPerSide;

          return Container(
            color: BattlePalette.panel,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                FilledButton.icon(
                  onPressed: state.canDispatch
                      ? () => _dispatch(context, state.formation)
                      : null,
                  icon: const Icon(Icons.play_arrow, size: 16),
                  label: const Text('Begin battle'),
                ),
                OutlinedButton(
                  onPressed: () => cubit.reset(kDefaultParty),
                  child: const Text('Default party'),
                ),
                OutlinedButton(
                  onPressed: state.placedCount == 0 ? null : cubit.clearAll,
                  child: const Text('Clear'),
                ),
                Text(
                  '${state.placedCount} of $slots slots filled',
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

  /// The party travels in the URL, so a composition is a link you can share or
  /// reload — the same reason the battle mockup has a path of its own.
  void _dispatch(BuildContext context, PartyFormation formation) =>
      context.go(
        Uri(
          path: BattleScreen.routePath,
          queryParameters: <String, String>{'party': formation.encode()},
        ).toString(),
      );
}
