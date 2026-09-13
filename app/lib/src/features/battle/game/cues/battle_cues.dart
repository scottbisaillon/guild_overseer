import 'dart:ui';

import 'package:flame/components.dart';

import '../../../../core/domain/cue_registry.dart';
import '../../../../core/domain/presentation.dart';
import '../components/floating_text_component.dart';
import '../components/projectile_component.dart';
import '../components/unit_component.dart';

/// Everything one cue needs in order to draw itself.
///
/// Handed to the builder rather than reached for, so a cue is a small function
/// of its inputs and adding one never means threading a new dependency through
/// the game.
class CueContext {
  const CueContext({
    required this.world,
    required this.origin,
    required this.destination,
    required this.color,
    this.source,
    this.target,
    this.label = '',
  });

  final World world;

  /// Where the caster stands, and where this cue is aimed.
  final Vector2 origin;
  final Vector2 destination;

  /// The palette colour the cue's authored [CueColor] resolved to.
  final Color color;

  /// The units involved, when they are on screen. A cue that moves a unit
  /// needs the component; one that only draws does not.
  final UnitComponent? source;
  final UnitComponent? target;

  /// Text for cues that write something — a status name, usually. Empty when
  /// the cue does not draw words.
  final String label;
}

/// Builds the registry the battle renderer draws with.
///
/// This function is the whole surface between "what content asks for" and
/// "what the screen does". A new visual is a component and one line here.
CueRegistry<CueContext> buildBattleCues() {
  final CueRegistry<CueContext> cues = CueRegistry<CueContext>();

  cues.register(Cue.lunge, (CueContext context) {
    context.source?.lungeToward(context.destination);
  });

  cues.register(Cue.bolt, (CueContext context) {
    context.world.add(ProjectileComponent(
      from: context.origin,
      to: context.destination,
      color: context.color,
    ));
  });

  cues.register(Cue.beam, (CueContext context) {
    context.world.add(BeamComponent(
      from: context.origin,
      to: context.destination,
      color: context.color,
    ));
  });

  cues.register(Cue.buffMark, _mark);
  cues.register(Cue.debuffMark, _mark);

  // The registry and the id list are kept honest against each other: content
  // can only name ids from Cue, and every one of them must land here.
  assert(
    cues.registered.toSet().difference(Cue.all).isEmpty &&
        Cue.all.difference(cues.registered.toSet()).isEmpty,
    'Registered cues and Cue.all have drifted apart.',
  );
  return cues;
}

/// A short label rising off a unit — what a status looks like arriving, until
/// there is art for it.
void _mark(CueContext context) {
  if (context.label.isEmpty) {
    return;
  }
  context.world.add(FloatingTextComponent(
    text: context.label,
    color: context.color,
    position: context.destination - Vector2(0, 42),
    fontSize: 13,
    rise: 30,
    lifetime: 1.1,
  ));
}
