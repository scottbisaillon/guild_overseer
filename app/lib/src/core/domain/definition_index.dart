/// A lookup from id to the content it names, that fails loudly when it misses.
///
/// The counterpart to `CueRegistry`, and deliberately its opposite: a missing
/// *visual* is a cosmetic gap a fight must survive, while a missing skill,
/// item or dungeon is a content bug that should stop the loader with the id in
/// the message rather than quietly producing a member who cannot attack.
///
/// Every system above combat refers to content by id — a member stores the id
/// of the sword it is wearing, not the sword — because that is what makes a
/// save a list of ids rather than a copy of the game's content. This is the
/// one place those ids turn back into definitions.
///
/// Generic over the definition type, with the id read by a function, so one
/// class serves skills, items, dungeons, traits and whatever comes next
/// without any of them implementing an interface to be indexed.
class DefinitionIndex<T> {
  /// Builds an index over [definitions]. Ids must be unique — a duplicate is
  /// a content bug that would otherwise silently shadow one of the two.
  factory DefinitionIndex(
    Iterable<T> definitions, {
    required String Function(T definition) idOf,
    String label = 'definition',
  }) {
    final Map<String, T> byId = <String, T>{};
    for (final T definition in definitions) {
      final String id = idOf(definition);
      assert(
        !byId.containsKey(id),
        'Two ${label}s share the id "$id"; ids must be unique.',
      );
      byId[id] = definition;
    }
    return DefinitionIndex._(Map<String, T>.unmodifiable(byId), label);
  }

  const DefinitionIndex._(this._byId, this._label);

  final Map<String, T> _byId;

  /// What this holds, for error messages: "skill", "item", "dungeon".
  final String _label;

  Iterable<String> get ids => _byId.keys;

  Iterable<T> get all => _byId.values;

  int get length => _byId.length;

  bool knows(String id) => _byId.containsKey(id);

  /// The definition named [id], or null. For the cases where absence is an
  /// ordinary answer — a save from an older version naming content that has
  /// since been removed, which is dropped rather than fatal.
  T? maybe(String id) => _byId[id];

  /// The definition named [id]. Throws when there is none.
  ///
  /// The message names what was missing and what is available, because the
  /// only useful thing to know at that moment is which of the two is the typo.
  T require(String id) {
    final T? found = _byId[id];
    if (found == null) {
      throw ArgumentError.value(
        id,
        '$_label id',
        'Unknown $_label. Known ids: ${ids.join(', ')}',
      );
    }
    return found;
  }

  /// Every definition in [ids], in the order given. Throws on the first
  /// unknown id, so a rotation naming one missing skill never half-loads.
  List<T> requireAll(Iterable<String> ids) =>
      <T>[for (final String id in ids) require(id)];

  /// Only the definitions that exist, unknown ids dropped. What a save load
  /// wants: a member whose third skill no longer exists keeps the other two.
  List<T> keepKnown(Iterable<String> ids) =>
      <T>[for (final String id in ids) if (maybe(id) case final T found) found];
}
