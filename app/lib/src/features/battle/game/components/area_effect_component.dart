import 'dart:ui';

import 'package:flame/components.dart';

/// How an area effect covers its ground.
enum AreaStyle {
  /// A bright edge wipes along the footprint's long axis, starting from the
  /// caster's end: a blow that travelled through a rank or a row.
  sweep,

  /// The whole footprint lights at once and spreads outward: a burst, a storm,
  /// a blessing over the party.
  pulse,
}

/// The ground a skill covered, drawn once, under the units standing on it.
///
/// An area attack used to look like several attacks that happened to land
/// together — three bolts, three numbers, no shape. This is the shape: the
/// footprint of the cells the skill reached, so a cleave through the front rank
/// reads as one blow that caught three units.
///
/// It draws the cells it is handed rather than a rank, a row or a radius. The
/// renderer never learns what [TargetShape] the skill used: a column comes out
/// as a tall footprint and a row as a wide one because that is the ground those
/// units are standing on, which is also why a shape nobody has thought of yet
/// will draw correctly the day it is authored.
class AreaEffectComponent extends PositionComponent {
  AreaEffectComponent({
    required List<Rect> cells,
    required this.color,
    required this.style,
    required Vector2 from,
    this.lifetime = 0.6,
  })  : _cells = List<Rect>.unmodifiable(cells),
        _footprint = coveredArea(cells),
        _from = from.clone(),
        // Under the units and the target lines, over the floor: the wash says
        // where the blow landed without hiding who it landed on.
        super(priority: 5);

  final List<Rect> _cells;
  final Rect _footprint;
  final Vector2 _from;

  final Color color;
  final AreaStyle style;

  /// Seconds from landing to gone.
  final double lifetime;

  double _age = 0;

  /// How much of [lifetime] the sweep takes to cross the footprint. The rest of
  /// the life is the wash fading behind it.
  static const double _sweepShare = 0.45;

  /// Half-thickness of the sweeping edge, in arena units.
  static const double _edgeHalfWidth = 13;

  /// How far a pulse spreads past its footprint before it is gone.
  static const double _pulseSpread = 14;

  static const Radius _corner = Radius.circular(8);

  /// Whether the footprint is taller than it is wide, and so whether a sweep
  /// runs down it or across it.
  bool get _isVertical => _footprint.height >= _footprint.width;

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
    // Bright on arrival and gone gently: squaring the remaining life holds the
    // first frames near full strength, which is what makes the shape register
    // at 4x speed as well as at 1x.
    final double fade = (1 - t) * (1 - t);
    final double spread = style == AreaStyle.pulse ? _pulseSpread * t : 0;
    final RRect footprint = RRect.fromRectAndRadius(
      _footprint.inflate(spread),
      _corner,
    );

    canvas.drawRRect(
      footprint,
      Paint()..color = color.withValues(alpha: 0.22 * fade),
    );
    canvas.drawRRect(
      footprint,
      Paint()
        ..color = color.withValues(alpha: 0.9 * fade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // The cells inside it, so the footprint says which units were caught and
    // not merely how much ground was covered.
    final Paint cellPaint = Paint()
      ..color = color.withValues(alpha: 0.5 * fade)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final Rect cell in _cells) {
      canvas.drawRRect(RRect.fromRectAndRadius(cell, _corner), cellPaint);
    }

    if (style == AreaStyle.sweep) {
      _renderSweep(canvas, t);
    }
  }

  /// The leading edge, travelling the long way across the footprint and away
  /// from the caster — the direction the blow went.
  void _renderSweep(Canvas canvas, double t) {
    final double progress = (t / _sweepShare).clamp(0.0, 1.0);
    if (progress >= 1) {
      return;
    }
    // Brightest mid-crossing, so the edge arrives and leaves rather than
    // blinking out against the far side.
    final double alpha = 0.85 * (1 - progress);

    final Rect edge = _isVertical
        ? _horizontalEdge(progress)
        : _verticalEdge(progress);

    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(_footprint, _corner));
    canvas.drawRect(edge, Paint()..color = color.withValues(alpha: alpha));
    canvas.restore();
  }

  /// The edge of a sweep running down a tall footprint.
  Rect _horizontalEdge(double progress) {
    final bool downward = _from.y <= _footprint.center.dy;
    final double y = downward
        ? _footprint.top + _footprint.height * progress
        : _footprint.bottom - _footprint.height * progress;
    return Rect.fromLTRB(
      _footprint.left,
      y - _edgeHalfWidth,
      _footprint.right,
      y + _edgeHalfWidth,
    );
  }

  /// The edge of a sweep running across a wide footprint.
  Rect _verticalEdge(double progress) {
    final bool rightward = _from.x <= _footprint.center.dx;
    final double x = rightward
        ? _footprint.left + _footprint.width * progress
        : _footprint.right - _footprint.width * progress;
    return Rect.fromLTRB(
      x - _edgeHalfWidth,
      _footprint.top,
      x + _edgeHalfWidth,
      _footprint.bottom,
    );
  }
}

/// The ground [cells] add up to, with a little air around it.
///
/// A pure function of the cells, so what an area effect covers can be checked
/// without a running game. Padding is what stops the footprint reading as a box
/// drawn tightly around the units: it is the ground they are standing on, not
/// their outline.
Rect coveredArea(Iterable<Rect> cells, {double padding = 10}) {
  Rect? bounds;
  for (final Rect cell in cells) {
    bounds = bounds == null ? cell : bounds.expandToInclude(cell);
  }
  return bounds == null ? Rect.zero : bounds.inflate(padding);
}
