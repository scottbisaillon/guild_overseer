import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' show FontWeight, TextStyle;

import '../../../../core/domain/skill_kind.dart';
import '../../domain/arena_layout.dart';
import '../../domain/combatant.dart';
import '../../view/battle_palette.dart';

/// One unit standing in its formation slot.
///
/// The component holds a reference to the live [Combatant] and reads from it
/// every frame; it never writes back. All movement here is presentational — a
/// lunge on a melee swing, a flinch on a hit — and always returns the unit to
/// the slot it was assigned. Units do not walk the arena in this mockup.
class UnitComponent extends PositionComponent {
  UnitComponent({required this.combatant, required this.layout})
      : _slot = Vector2(
          layout.slotCentre(combatant.faction, combatant.row, combatant.column).x,
          layout.slotCentre(combatant.faction, combatant.row, combatant.column).y,
        ),
        super(
          size: Vector2.all(layout.cellSize),
          anchor: Anchor.center,
          priority: 20,
        ) {
    position = _slot.clone();
  }

  final Combatant combatant;
  final ArenaLayout layout;

  final Vector2 _slot;

  /// Counts down while the unit is mid-swing.
  double _castFlash = 0;

  /// Counts down while the unit is flinching from a hit.
  double _hitFlash = 0;

  double _lungeTimer = 0;
  Vector2 _lungeDirection = Vector2.zero();

  /// 0 while alive, ramps to 1 as the unit fades out on death.
  double _deathFade = 0;

  static const double _castDuration = 0.3;
  static const double _hitDuration = 0.24;
  static const double _lungeDuration = 0.26;
  static const double _lungeReach = 30;

  static final TextPaint _glyphPaint = TextPaint(
    style: const TextStyle(
      color: Color(0xFFF2F4FA),
      fontSize: 30,
      fontWeight: FontWeight.w700,
    ),
  );

  static final TextPaint _namePaint = TextPaint(
    style: const TextStyle(
      color: BattlePalette.textMuted,
      fontSize: 11,
      fontWeight: FontWeight.w500,
    ),
  );

  /// Called when this unit fires a skill.
  void playCast(SkillDelivery delivery, Vector2 targetPosition) {
    _castFlash = _castDuration;
    if (delivery == SkillDelivery.melee) {
      final Vector2 toTarget = targetPosition - _slot;
      if (!toTarget.isZero()) {
        _lungeDirection = toTarget.normalized();
        _lungeTimer = _lungeDuration;
      }
    }
  }

  /// Called when this unit takes a hit.
  void playHit() => _hitFlash = _hitDuration;

  @override
  void update(double dt) {
    super.update(dt);

    _castFlash = math.max(0, _castFlash - dt);
    _hitFlash = math.max(0, _hitFlash - dt);
    _lungeTimer = math.max(0, _lungeTimer - dt);
    if (!combatant.isAlive && _deathFade < 1) {
      _deathFade = math.min(1, _deathFade + dt * 3);
    }

    Vector2 offset = Vector2.zero();

    if (_lungeTimer > 0) {
      // Out and back in one arc, so the unit always ends up on its slot.
      final double progress = 1 - _lungeTimer / _lungeDuration;
      offset += _lungeDirection * (math.sin(progress * math.pi) * _lungeReach);
    }

    if (_hitFlash > 0) {
      final double shake = math.sin(_hitFlash * 70) * _hitFlash * 18;
      offset += Vector2(shake, 0);
    }

    position = _slot + offset;
  }

  @override
  void render(Canvas canvas) {
    final bool alive = combatant.isAlive;
    final Rect body = Rect.fromLTWH(6, 6, size.x - 12, size.y - 12);
    final Color factionColor = BattlePalette.faction(combatant.faction);
    final Color roleColor = BattlePalette.role(combatant.role);

    final Color livingFill =
        Color.lerp(factionColor.withValues(alpha: 0.32), factionColor, 0.25)!;
    Color fill = alive
        ? livingFill
        : Color.lerp(
            livingFill,
            BattlePalette.dead.withValues(alpha: 0.22),
            _deathFade,
          )!;
    if (alive && _castFlash > 0) {
      fill = Color.lerp(fill, factionColor, _castFlash / _castDuration * 0.7)!;
    }
    if (alive && _hitFlash > 0) {
      fill = Color.lerp(
        fill,
        const Color(0xFFFFFFFF),
        _hitFlash / _hitDuration * 0.55,
      )!;
    }

    canvas.drawRect(body, Paint()..color = fill);
    canvas.drawRect(
      body,
      Paint()
        ..color = alive
            ? roleColor.withValues(alpha: 0.9)
            : Color.lerp(
                roleColor.withValues(alpha: 0.9),
                BattlePalette.dead.withValues(alpha: 0.6),
                _deathFade,
              )!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    if (alive && _castFlash > 0) {
      canvas.drawRect(
        body.inflate(4),
        Paint()
          ..color = factionColor.withValues(
            alpha: (_castFlash / _castDuration) * 0.8,
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    _glyphPaint.render(
      canvas,
      combatant.role.glyph,
      Vector2(size.x / 2, size.y / 2 + 2),
      anchor: Anchor.center,
    );

    _namePaint.render(
      canvas,
      combatant.name,
      Vector2(size.x / 2, size.y + 4),
      anchor: Anchor.topCenter,
    );

    if (alive) {
      _renderHealthBar(canvas, factionColor);
    } else {
      _renderDeathMark(canvas, body);
    }
  }

  void _renderHealthBar(Canvas canvas, Color factionColor) {
    const double barHeight = 7;
    final Rect track = Rect.fromLTWH(6, -14, size.x - 12, barHeight);
    canvas.drawRect(track, Paint()..color = const Color(0xFF0B0D14));
    canvas.drawRect(
      Rect.fromLTWH(
        track.left,
        track.top,
        track.width * combatant.healthFraction,
        barHeight,
      ),
      Paint()..color = factionColor,
    );
    canvas.drawRect(
      track,
      Paint()
        ..color = const Color(0xFF2A2F3E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _renderDeathMark(Canvas canvas, Rect body) {
    final Paint paint = Paint()
      ..color = BattlePalette.dead.withValues(alpha: 0.8 * _deathFade)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(body.topLeft, body.bottomRight, paint);
    canvas.drawLine(body.topRight, body.bottomLeft, paint);
  }
}
