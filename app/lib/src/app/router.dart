import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/battle/domain/party_formation.dart';
import '../features/battle/view/battle_screen.dart';
import '../features/home/view/home_screen.dart';
import '../features/party/view/party_screen.dart';

/// App routes.
///
/// Three exist so far: the shell, party select and the battle mockup. The
/// guild hall, tavern and skill editor screens slot in beside them.
///
/// A composed party rides in the `party` query parameter rather than in
/// `GoRouterState.extra`, so `/battle?party=…` is a link that survives a
/// reload and can be shared — `extra` is dropped by both. What the parameter
/// says is not trusted: [PartyFormation.decode] keeps the entries it can read
/// and the roster builder drops units it has never heard of.
GoRouter buildRouter() => GoRouter(
      routes: <RouteBase>[
        GoRoute(
          path: HomeScreen.routePath,
          builder: (BuildContext context, GoRouterState state) =>
              const HomeScreen(),
          routes: <RouteBase>[
            GoRoute(
              path: 'party',
              builder: (BuildContext context, GoRouterState state) =>
                  PartyScreen(initialParty: _partyOf(state)),
            ),
            GoRoute(
              path: 'battle',
              builder: (BuildContext context, GoRouterState state) =>
                  BattleScreen(party: _partyOf(state)),
            ),
          ],
        ),
      ],
    );

/// The party carried by this route, or null when it carries none.
PartyFormation? _partyOf(GoRouterState state) {
  final PartyFormation party =
      PartyFormation.decode(state.uri.queryParameters['party']);
  return party.isEmpty ? null : party;
}
