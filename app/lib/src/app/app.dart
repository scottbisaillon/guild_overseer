import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'router.dart';
import 'theme.dart';

/// The application shell.
class GuildOverseerApp extends StatefulWidget {
  const GuildOverseerApp({super.key});

  @override
  State<GuildOverseerApp> createState() => _GuildOverseerAppState();
}

class _GuildOverseerAppState extends State<GuildOverseerApp> {
  late final GoRouter _router = buildRouter();

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: 'Guild Overseer',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        routerConfig: _router,
      );
}
