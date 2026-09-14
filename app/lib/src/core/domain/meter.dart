import 'package:equatable/equatable.dart';

/// A bounded number describing how a guild member is doing.
///
/// Morale, loyalty and fatigue are the same shape — a 0–100 value that systems
/// nudge up and down from every direction — and the shape is worth a type
/// because the interesting part is the clamping. A failed run costs morale, a
/// drama event costs more, and a trait may cost more again; written as bare
/// doubles that is three subtractions and three places where a member can end
/// up at -14 morale and start reading as a negative multiplier somewhere far
/// away. Here it is impossible: a [Meter] cannot hold a value outside its
/// range, so the clamp cannot be the thing somebody forgot.
///
/// Immutable, like everything a member is made of: [adjustedBy] hands back a
/// new meter rather than moving this one, so a member is a value that can be
/// compared with its former self to see what a run did to it.
class Meter extends Equatable {
  /// Clamps into range. Handing it 140 is not an error — it is what every
  /// caller that stacks bonuses produces, and the answer is 100.
  factory Meter(double value) => Meter._(value.clamp(minimum, maximum));

  const Meter._(this.value);

  /// The floor and ceiling every meter shares. See [[docs/systems/members]] —
  /// morale, loyalty and fatigue are all defined over the same range, and
  /// keeping it that way is what lets one type serve all three.
  static const double minimum = 0;
  static const double maximum = 100;

  /// A member in the best possible shape on this axis. Note that for fatigue
  /// this is the *worst* state to be in: the meter does not know which
  /// direction is good, only what the number is.
  static const Meter full = Meter._(maximum);

  static const Meter empty = Meter._(minimum);

  /// The midpoint, and the value a freshly rolled recruit starts morale and
  /// loyalty at unless something says otherwise.
  static const Meter half = Meter._((minimum + maximum) / 2);

  final double value;

  /// 0.0 at [minimum], 1.0 at [maximum]. What a progress bar wants.
  double get fraction => (value - minimum) / (maximum - minimum);

  bool get isFull => value >= maximum;

  bool get isEmpty => value <= minimum;

  /// This meter [delta] higher, clamped. Negative deltas drain it.
  Meter adjustedBy(double delta) => Meter(value + delta);

  /// This meter set to [next], clamped. For the rare case that sets a value
  /// outright — a rest that restores fatigue to zero — rather than moving it.
  Meter setTo(double next) => Meter(next);

  bool isBelow(double threshold) => value < threshold;

  bool isAtLeast(double threshold) => value >= threshold;

  double toJson() => value;

  static Meter fromJson(Object? json) =>
      Meter((json as num?)?.toDouble() ?? minimum);

  @override
  List<Object?> get props => <Object?>[value];

  @override
  String toString() => value.toStringAsFixed(1);
}
