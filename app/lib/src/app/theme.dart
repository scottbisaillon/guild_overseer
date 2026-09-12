import 'package:flutter/material.dart';

import '../features/battle/view/battle_palette.dart';

/// Retro-minimalist shell: flat fills, square corners, monospace type.
///
/// Everything here is deliberately plain — the art direction lands later, and
/// a scaffold that looks finished invites arguments about the wrong things.
ThemeData buildAppTheme() {
  const ColorScheme scheme = ColorScheme.dark(
    primary: BattlePalette.ally,
    onPrimary: Color(0xFF0B0D14),
    secondary: BattlePalette.enemy,
    surface: BattlePalette.panel,
    onSurface: BattlePalette.textPrimary,
  );

  const List<String> monospace = <String>[
    'monospace',
    'Menlo',
    'Consolas',
    'DejaVu Sans Mono',
  ];

  const RoundedRectangleBorder squared = RoundedRectangleBorder(
    borderRadius: BorderRadius.zero,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamilyFallback: monospace,
    scaffoldBackgroundColor: BattlePalette.background,
    dividerColor: BattlePalette.gridLine,
    appBarTheme: const AppBarTheme(
      backgroundColor: BattlePalette.panel,
      foregroundColor: BattlePalette.textPrimary,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: const CardThemeData(
      color: BattlePalette.panel,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: squared,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(shape: squared),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(shape: squared),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(shape: squared),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        shape: squared,
        selectedBackgroundColor: BattlePalette.ally,
        selectedForegroundColor: const Color(0xFF0B0D14),
      ),
    ),
    tooltipTheme: const TooltipThemeData(
      decoration: BoxDecoration(color: BattlePalette.gridLine),
    ),
  );
}
