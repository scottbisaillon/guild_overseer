/// Which palette role a cue paints itself with.
///
/// Named for what it means, not what colour it is, so a retheme is a change to
/// the palette rather than to every skill in the game.
enum CueColor {
  /// The caster's own side colour — the default for an attack.
  source,

  /// Restoration.
  heal,

  /// Harm.
  damage,

  /// Something good, arriving.
  buff,

  /// Something bad, arriving.
  debuff,
}

/// The cue ids the battle renderer knows how to draw.
///
/// Content refers to these constants rather than to bare strings, so a typo is
/// a compile error instead of a silently missing effect, and so a test can
/// check that everything referenced is something the renderer registers.
///
/// Adding a visual is: write the component, register it under a new id here,
/// and name it from the content. No rules code is touched, and no switch
/// anywhere grows an arm.
abstract final class Cue {
  /// The caster lunges at its target and snaps back to its slot.
  static const String lunge = 'lunge';

  /// A bolt travels from caster to target.
  static const String bolt = 'bolt';

  /// A beam is drawn between caster and target for a moment.
  static const String beam = 'beam';

  /// A label rises off a unit that has just gained something.
  static const String buffMark = 'buff_mark';

  /// A label rises off a unit that has just gained something unpleasant.
  static const String debuffMark = 'debuff_mark';

  /// The ground a skill covered, wiped through once along its long axis — a
  /// blow that swept a rank or a row.
  static const String areaSweep = 'area_sweep';

  /// The ground a skill covered, lighting up all at once and spreading — a
  /// burst, a storm, a blessing over the whole party.
  static const String areaPulse = 'area_pulse';

  /// Every id above. The renderer registers exactly this set.
  static const Set<String> all = <String>{
    lunge,
    bolt,
    beam,
    buffMark,
    debuffMark,
    areaSweep,
    areaPulse,
  };
}

/// How something looks when it happens.
///
/// Presentation is authored beside the rules but resolved separately: these are
/// ids the renderer looks up, never types it switches on. That is what lets the
/// renderer gain an effect without the simulation knowing, and the simulation
/// gain a skill without the renderer knowing.
class PresentationSpec {
  const PresentationSpec({
    this.cast,
    this.travel,
    this.impact,
    this.area,
    this.color = CueColor.source,
  });

  /// Nothing to draw. Used by anything whose visuals have not been authored
  /// yet, which is better than inventing some.
  static const PresentationSpec none = PresentationSpec();

  /// Played once on the caster.
  final String? cast;

  /// Played once per target, between caster and target.
  final String? travel;

  /// Played once per target, at the target.
  final String? impact;

  /// Played once for the skill, over everything it landed on at once.
  ///
  /// [travel] and [impact] describe one unit being hit, and repeating them is
  /// how a skill that catches three units reads as three separate hits. This
  /// is the other half: the shape the blow covered, drawn once, which is what
  /// makes an area attack legible as one blow rather than a coincidence.
  ///
  /// Authored, not inferred from the number of targets: a skill whose effects
  /// point at different sides — damage the enemy, buff the caster — lands on
  /// several units without covering any ground between them.
  final String? area;

  final CueColor color;

  /// Every cue this spec names, for validation.
  Iterable<String> get cueIds =>
      <String?>[cast, travel, impact, area].whereType<String>();
}
