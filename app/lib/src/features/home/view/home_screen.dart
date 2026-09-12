import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../battle/view/battle_palette.dart';

/// Landing screen. A placeholder for the guild hall hub, with the one thing
/// that is actually built so far wired up.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const String routePath = '/';

  static const List<String> _plannedScreens = <String>[
    'Guild Hall — hub, roster, event feed',
    'Tavern — recruitment pool and trait badges',
    'Skill Editor — skill tree and rotation builder',
    'Party Composer — dungeon select and dispatch',
    'Loot Distribution — post-run assignment',
  ];

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'GUILD OVERSEER',
                  style: text.headlineMedium?.copyWith(
                    letterSpacing: 6,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Idle / active management sim — Flutter + Flame scaffold',
                  style: text.bodyMedium?.copyWith(
                    color: BattlePalette.textMuted,
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: () => context.go('/battle'),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    child: Text('Open battle mockup'),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'NOT BUILT YET',
                  style: text.labelMedium?.copyWith(
                    color: BattlePalette.textMuted,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 12),
                for (final String screen in _plannedScreens)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '· $screen',
                      style: text.bodySmall?.copyWith(
                        color: BattlePalette.dead,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
