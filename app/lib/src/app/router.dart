import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/battle/view/battle_screen.dart';
import '../features/home/view/home_screen.dart';

/// App routes.
///
/// Only two exist so far: the shell and the battle mockup. The guild hall,
/// tavern, skill editor and party composer screens slot in beside them.
GoRouter buildRouter() => GoRouter(
      routes: <RouteBase>[
        GoRoute(
          path: HomeScreen.routePath,
          builder: (BuildContext context, GoRouterState state) =>
              const HomeScreen(),
          routes: <RouteBase>[
            GoRoute(
              path: 'battle',
              builder: (BuildContext context, GoRouterState state) =>
                  const BattleScreen(),
            ),
          ],
        ),
      ],
    );
