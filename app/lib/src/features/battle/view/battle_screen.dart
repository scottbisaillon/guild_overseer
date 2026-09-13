import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/faction.dart';
import '../../../core/events/game_event.dart';
import '../../party/view/party_screen.dart';
import '../bloc/battle_bloc.dart';
import '../bloc/battle_state.dart';
import '../data/mock_roster.dart';
import '../domain/battle_simulation.dart';
import '../domain/party_formation.dart';
import '../domain/party_skills.dart';
import '../game/battle_game.dart';
import 'battle_palette.dart';
import 'widgets/battle_controls.dart';
import 'widgets/battle_result_banner.dart';
import 'widgets/combat_log_panel.dart';
import 'widgets/roster_panel.dart';

/// The battle mockup: two formations, stationary, trading skills until one side
/// is gone.
///
/// This is the integration pattern the rest of the game follows — a Flame
/// `GameWidget` under Flutter HUD widgets, with the simulation's event stream
/// as the only wire between them.
class BattleScreen extends StatefulWidget {
  const BattleScreen({this.party, this.skills, super.key});

  static const String routePath = '/battle';

  /// The party the player composed, or null to fight the authored one. Held
  /// for the life of the screen: a restart rebuilds the same roster, so the
  /// fight being watched again is the fight that was watched.
  final PartyFormation? party;

  /// The skills that party chose, or null to fight with the authored ones.
  final PartySkills? skills;

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  late final BattleSimulation _simulation;
  late final BattleGame _game;
  late final BattleBloc _bloc;

  bool _showTargetLines = true;

  /// Below this width the side panels stop fitting beside the arena.
  static const double _wideLayoutBreakpoint = 980;

  @override
  void initState() {
    super.initState();
    _simulation = BattleSimulation(
      rosterBuilder: () => buildRoster(
        party: widget.party ?? kDefaultParty,
        skills: widget.skills ?? const PartySkills.empty(),
      ),
    );
    _game = BattleGame(simulation: _simulation);
    _bloc = BattleBloc(
      simulation: _simulation,
      onRosterRebuilt: _game.rebuild,
    )..add(const StartBattleRequested());
  }

  @override
  void dispose() {
    _bloc.close();
    _simulation.dispose();
    super.dispose();
  }

  /// Back the way the player came, carrying the party with it, so returning
  /// to the screen they composed on does not hand them an empty board.
  String _backDestination() => switch (widget.party) {
        final PartyFormation party => Uri(
            path: PartyScreen.routePath,
            queryParameters: <String, String>{
              'party': party.encode(),
              if (widget.skills case final PartySkills skills)
                if (skills.isNotEmpty) 'skills': skills.encode(),
            },
          ).toString(),
        null => '/',
      };

  void _setTargetLines(bool value) {
    setState(() => _showTargetLines = value);
    _game.showTargetLines = value;
  }

  @override
  Widget build(BuildContext context) => BlocProvider<BattleBloc>.value(
        value: _bloc,
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: widget.party == null ? 'Home' : 'Back to party select',
              onPressed: () => context.go(_backDestination()),
            ),
            title: const Text(
              'BATTLE MOCKUP',
              style: TextStyle(fontSize: 14, letterSpacing: 4),
            ),
          ),
          body: Column(
            children: <Widget>[
              BattleControls(
                showTargetLines: _showTargetLines,
                onToggleTargetLines: _setTargetLines,
              ),
              const Divider(height: 1),
              Expanded(
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) =>
                      constraints.maxWidth >= _wideLayoutBreakpoint
                          ? _wideLayout()
                          : _narrowLayout(),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _wideLayout() => Row(
        children: <Widget>[
          const RosterPanel(faction: Faction.ally),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: <Widget>[
                Expanded(child: _arena()),
                const Divider(height: 1),
                SizedBox(height: 170, child: const CombatLogPanel()),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          const RosterPanel(faction: Faction.enemy),
        ],
      );

  Widget _narrowLayout() => Column(
        children: <Widget>[
          const RosterStrip(faction: Faction.ally),
          Expanded(flex: 3, child: _arena()),
          const RosterStrip(faction: Faction.enemy),
          const Divider(height: 1),
          Expanded(child: const CombatLogPanel()),
        ],
      );

  Widget _arena() => ColoredBox(
        color: BattlePalette.background,
        child: Stack(
          children: <Widget>[
            Positioned.fill(child: GameWidget<BattleGame>(game: _game)),
            Positioned.fill(
              child: BlocBuilder<BattleBloc, BattleState>(
                buildWhen: (BattleState previous, BattleState current) =>
                    previous.isFinished != current.isFinished ||
                    previous.winner != current.winner,
                builder: (BuildContext context, BattleState state) =>
                    state.isFinished
                        ? BattleResultBanner(state: state)
                        : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      );
}
