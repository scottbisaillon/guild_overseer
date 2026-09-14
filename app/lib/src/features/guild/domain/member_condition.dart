import '../../../core/domain/meter.dart';
import '../../../core/domain/stat.dart';
import '../../../core/domain/stat_modifier.dart';
import 'member.dart';

/// What a member's condition is worth in a fight.
///
/// [[docs/systems/members]] says morale "affects performance" and fatigue is
/// something to be recovered from, and stops there — deliberately, because
/// what they are worth is balance rather than architecture. This is where that
/// number lives, on its own, so that retuning it is editing two constants in
/// one file and nothing else in the game moves.
///
/// The mechanism is the interesting part and it is not new: condition is
/// expressed as [StatModifier]s and granted at spawn like a breastplate or a
/// buff. Nothing in the fight can tell a demoralised member from a cursed one,
/// which is exactly the property that let gear land in an afternoon.
abstract final class MemberCondition {
  /// Granted under [ModifierSourceKind.passive] rather than a kind of its own:
  /// condition is something a member simply has, and a tooltip grouping it
  /// with traits and class passives is grouping it correctly.
  static const ModifierSource moraleSource = ModifierSource.passive('morale');
  static const ModifierSource fatigueSource = ModifierSource.passive('fatigue');

  /// Output swing at the ends of the morale meter. First-pass tuning: a
  /// member at 100 morale hits 10% harder than at 50, and one at 0 hits 10%
  /// softer. Enough to be worth managing, not enough to make a sulking party
  /// unusable.
  static const double moraleOutputSwing = 0.10;

  /// Health lost at full fatigue. First-pass tuning: an exhausted member is
  /// 20% easier to kill, which is the pressure that makes rest a decision
  /// rather than a formality.
  static const double fatigueHealthPenalty = 0.20;

  /// The midpoint of morale, where it is worth nothing either way.
  static const double _moraleNeutral = Meter.maximum / 2;

  /// What [member]'s morale and fatigue are worth right now.
  ///
  /// Only non-zero modifiers are returned, so a rested member at neutral
  /// morale arrives carrying nothing at all rather than a list of zeroes.
  static List<StatModifier> modifiersFor(Member member) => <StatModifier>[
        ...moraleModifiers(member.morale),
        ...fatigueModifiers(member.fatigue),
      ];

  /// Scales damage and healing alike: morale is how well somebody is playing,
  /// not how hard they swing, so it should not quietly favour damage roles.
  static List<StatModifier> moraleModifiers(Meter morale) {
    final double swing =
        (morale.value - _moraleNeutral) / _moraleNeutral * moraleOutputSwing;
    if (swing == 0) {
      return const <StatModifier>[];
    }
    return <StatModifier>[
      StatModifier.increased(Stat.attackPower, swing, source: moraleSource),
      StatModifier.increased(Stat.healPower, swing, source: moraleSource),
    ];
  }

  /// Costs health rather than output, so fatigue reads as wear rather than as
  /// a second morale — the two meters should not be the same lever twice.
  static List<StatModifier> fatigueModifiers(Meter fatigue) {
    if (fatigue.isEmpty) {
      return const <StatModifier>[];
    }
    return <StatModifier>[
      StatModifier.increased(
        Stat.maxHealth,
        -fatigue.fraction * fatigueHealthPenalty,
        source: fatigueSource,
      ),
    ];
  }
}
