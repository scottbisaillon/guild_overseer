import 'dart:ui';

import 'package:flame/components.dart';

/// A bolt, arrow or mote travelling from a caster to its target.
///
/// Purely cosmetic: the damage has already been applied by the simulation when
/// this spawns. It exists so the player can see who is shooting whom.
class ProjectileComponent extends PositionComponent {
  ProjectileComponent({
    required Vector2 from,
    required Vector2 to,
    required this.color,
    this.speed = 1100,
  })  : _from = from.clone(),
        _to = to.clone(),
        super(priority: 30) {
    final double distance = _to.distanceTo(_from);
    _duration = (distance / speed).clamp(0.08, 0.6);
  }

  final Vector2 _from;
  final Vector2 _to;
  final Color color;
  final double speed;

  late final double _duration;
  double _age = 0;

  static const double _radius = 5;

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    if (_age >= _duration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final double t = (_age / _duration).clamp(0.0, 1.0);
    final Vector2 head = _from + (_to - _from) * t;
    final Vector2 tail = _from + (_to - _from) * (t - 0.12).clamp(0.0, 1.0);

    canvas.drawLine(
      Offset(tail.x, tail.y),
      Offset(head.x, head.y),
      Paint()
        ..color = color.withValues(alpha: 0.45)
        ..strokeWidth = _radius
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      Offset(head.x, head.y),
      _radius,
      Paint()..color = color,
    );
  }
}

/// A beam snapped between caster and target for a moment — used by casters and
/// healers, where a travelling projectile would read as too slow.
class BeamComponent extends PositionComponent {
  BeamComponent({
    required Vector2 from,
    required Vector2 to,
    required this.color,
    this.lifetime = 0.24,
  })  : _from = from.clone(),
        _to = to.clone(),
        super(priority: 30);

  final Vector2 _from;
  final Vector2 _to;
  final Color color;
  final double lifetime;

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
    final double opacity = 1 - t;
    canvas.drawLine(
      Offset(_from.x, _from.y),
      Offset(_to.x, _to.y),
      Paint()
        ..color = color.withValues(alpha: opacity * 0.8)
        ..strokeWidth = 3 + 3 * (1 - t)
        ..strokeCap = StrokeCap.round,
    );
  }
}
