import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' show FontWeight, TextStyle;

/// A damage or healing number that rises off a unit and fades out.
class FloatingTextComponent extends PositionComponent {
  FloatingTextComponent({
    required this.text,
    required this.color,
    required Vector2 position,
    this.lifetime = 0.85,
    this.rise = 46,
    this.fontSize = 20,
  }) : super(position: position, priority: 40);

  final String text;
  final Color color;

  /// Seconds before the number disappears.
  final double lifetime;

  /// How far it travels upward over its lifetime.
  final double rise;

  final double fontSize;

  double _age = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    if (_age >= lifetime) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final double t = (_age / lifetime).clamp(0.0, 1.0);
    // Fast at first, then drifting — the number is readable while it matters.
    final double eased = 1 - (1 - t) * (1 - t);
    final double opacity = t < 0.6 ? 1 : 1 - (t - 0.6) / 0.4;

    TextPaint(
      style: TextStyle(
        color: color.withValues(alpha: opacity.clamp(0.0, 1.0)),
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        shadows: const <Shadow>[
          Shadow(color: Color(0xCC000000), blurRadius: 4),
        ],
      ),
    ).render(
      canvas,
      text,
      Vector2(0, -rise * eased),
      anchor: Anchor.center,
    );
  }
}
