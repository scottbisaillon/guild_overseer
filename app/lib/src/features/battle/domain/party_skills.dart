import 'package:equatable/equatable.dart';

/// How many skills of their own a unit may be given.
///
/// A cap rather than a requirement: a rotation of one is legal, and so is a
/// rotation of none — a unit that chose nothing still has its basic attack.
/// The number is small because rotation order is priority order, and a long
/// rotation is one whose tail never fires.
const int kChosenSkillSlots = 3;

/// Which skills each unit is taking, before a fight starts.
///
/// The companion to [PartyFormation]: that answers who is going and where they
/// stand, this answers what they bring. Immutable for the same reason — every
/// edit hands back a new value, so a party is one thing to write down, encode
/// into a link, or hand to the roster builder.
///
/// A unit with no entry here fights with the skills it was authored with. That
/// is what makes this an override rather than a requirement: the screen can
/// open on an empty selection and every unit is still a complete unit.
///
/// Skill ids are not checked against any catalogue, exactly as unit ids are
/// not checked by a formation. This type does not know what skills exist;
/// whoever builds the roster does, and drops the ones it has never heard of.
class PartySkills extends Equatable {
  PartySkills(Map<String, List<String>> choices)
      : choices = Map<String, List<String>>.unmodifiable(<String, List<String>>{
          for (final MapEntry<String, List<String>> entry in choices.entries)
            entry.key: _normalise(entry.value),
        });

  const PartySkills.empty() : choices = const <String, List<String>>{};

  /// Unit id -> the ids of the skills it takes, in rotation order.
  final Map<String, List<String>> choices;

  /// How a selection travels in a URL: `unit:skill.skill`, comma separated.
  static const String _entrySeparator = ',';
  static const String _unitSeparator = ':';
  static const String _skillSeparator = '.';

  bool get isEmpty => choices.isEmpty;

  bool get isNotEmpty => choices.isNotEmpty;

  /// The skills chosen for [unitId], or null when the player has not chosen
  /// for it and it fights with what it was authored with.
  List<String>? forUnit(String unitId) => choices[unitId];

  /// Whether [unitId] has been customised at all. An empty list is a choice —
  /// "nothing but your basic attack" — and is not the same as no choice.
  bool hasChoiceFor(String unitId) => choices.containsKey(unitId);

  /// Gives [unitId] exactly [skillIds], in the order they are given.
  ///
  /// Duplicates are dropped and anything past [kChosenSkillSlots] is cut, so
  /// a caller never has to check the rules before calling: the value that
  /// comes back is one a unit could actually fight with.
  PartySkills withUnit(String unitId, List<String> skillIds) => PartySkills(
        Map<String, List<String>>.of(choices)..[unitId] = skillIds,
      );

  /// Hands [unitId] back to the skills it was authored with.
  PartySkills clearUnit(String unitId) => hasChoiceFor(unitId)
      ? PartySkills(Map<String, List<String>>.of(choices)..remove(unitId))
      : this;

  /// Drops every unit not named in [unitIds] — the party that is actually
  /// going. Keeps a link from carrying the loadout of somebody left behind.
  PartySkills retaining(Iterable<String> unitIds) {
    final Set<String> keep = unitIds.toSet();
    return PartySkills(<String, List<String>>{
      for (final MapEntry<String, List<String>> entry in choices.entries)
        if (keep.contains(entry.key)) entry.key: entry.value,
    });
  }

  /// This selection as one URL-safe token, alongside the formation's own.
  String encode() => <String>[
        for (final MapEntry<String, List<String>> entry in choices.entries)
          '${entry.key}$_unitSeparator'
              '${entry.value.join(_skillSeparator)}',
      ].join(_entrySeparator);

  /// Reads back what [encode] wrote.
  ///
  /// Lenient like [PartyFormation.decode], and for the same reason: a stale or
  /// hand-edited link is worth the entries it can still read. An entry naming
  /// no skills is a unit deliberately taking none, which is why it survives.
  static PartySkills decode(String? encoded) {
    if (encoded == null || encoded.isEmpty) {
      return const PartySkills.empty();
    }
    final Map<String, List<String>> choices = <String, List<String>>{};
    for (final String entry in encoded.split(_entrySeparator)) {
      final int split = entry.indexOf(_unitSeparator);
      if (split <= 0) {
        continue;
      }
      final String unitId = entry.substring(0, split);
      // First writer wins, so a malformed link cannot give one unit two
      // rotations.
      if (choices.containsKey(unitId)) {
        continue;
      }
      choices[unitId] = entry.substring(split + 1).split(_skillSeparator);
    }
    return PartySkills(choices);
  }

  /// The rules of a rotation, applied in one place: no duplicates, and no more
  /// than the slots a unit has.
  static List<String> _normalise(List<String> skillIds) {
    final List<String> kept = <String>[];
    for (final String id in skillIds) {
      if (id.isEmpty || kept.contains(id)) {
        continue;
      }
      kept.add(id);
      if (kept.length == kChosenSkillSlots) {
        break;
      }
    }
    return List<String>.unmodifiable(kept);
  }

  @override
  List<Object?> get props => <Object?>[
        // Equatable compares maps by value, but not the lists inside one.
        for (final MapEntry<String, List<String>> entry in choices.entries)
          '${entry.key}:${entry.value.join(',')}',
      ];
}
