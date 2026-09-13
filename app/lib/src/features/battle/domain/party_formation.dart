import 'package:equatable/equatable.dart';

import 'arena_layout.dart';

/// One cell of a formation grid: which row, and how far back from the centre.
///
/// A record rather than a class, so two slots naming the same cell are the same
/// key in a map without any equality written for them.
typedef FormationSlot = ({int row, int column});

/// Who stands where, before a fight starts.
///
/// Immutable: every edit hands back a new formation. The party screen holds one
/// of these and nothing else — the board it draws is a rendering of this value,
/// so an undo, a URL or a saved party is the same thing written down.
///
/// A slot holds at most one unit and a unit stands in at most one slot, and
/// both halves are enforced here rather than by whoever is calling. That is
/// what makes [place] a single operation the UI can hand every gesture to:
/// dropping onto an occupied cell swaps, dragging out of the grid removes, and
/// neither case needs the caller to unpick the previous state first.
class PartyFormation extends Equatable {
  const PartyFormation(this.placements);

  const PartyFormation.empty() : placements = const <FormationSlot, String>{};

  /// Slot -> the id of the unit blueprint standing in it.
  final Map<FormationSlot, String> placements;

  /// How the formation travels in a URL: `id:row:column`, comma separated.
  static const String _entrySeparator = ',';
  static const String _fieldSeparator = ':';

  bool get isEmpty => placements.isEmpty;

  bool get isNotEmpty => placements.isNotEmpty;

  int get size => placements.length;

  /// The unit standing at [slot], if any.
  String? at(FormationSlot slot) => placements[slot];

  /// Where [unitId] is standing, if it is placed at all.
  FormationSlot? slotOf(String unitId) {
    for (final MapEntry<FormationSlot, String> entry in placements.entries) {
      if (entry.value == unitId) {
        return entry.key;
      }
    }
    return null;
  }

  bool contains(String unitId) => placements.containsValue(unitId);

  /// Puts [unitId] in [slot], moving it off any slot it already held.
  ///
  /// If somebody is already standing there the two trade places — or, when the
  /// arriving unit came from the bench rather than the board, the occupant is
  /// sent back to it. A swap is what a player means by dropping one unit onto
  /// another, and it is the only reading that never silently loses a member.
  PartyFormation place(String unitId, FormationSlot slot) {
    final FormationSlot? from = slotOf(unitId);
    if (from == slot) {
      return this;
    }
    final String? displaced = placements[slot];

    final Map<FormationSlot, String> next =
        Map<FormationSlot, String>.of(placements)
          ..remove(from)
          ..remove(slot)
          ..[slot] = unitId;
    if (displaced != null && from != null) {
      next[from] = displaced;
    }
    return PartyFormation(next);
  }

  /// Empties [slot], benching whoever stood there.
  PartyFormation clearSlot(FormationSlot slot) => placements.containsKey(slot)
      ? PartyFormation(
          Map<FormationSlot, String>.of(placements)..remove(slot),
        )
      : this;

  /// Benches [unitId] wherever it is standing.
  PartyFormation remove(String unitId) {
    final FormationSlot? slot = slotOf(unitId);
    return slot == null ? this : clearSlot(slot);
  }

  /// Placed units in formation order — front line first, top to bottom.
  ///
  /// Deterministic, because this is the order units are spawned in and the
  /// simulation steps them in the order it is given.
  List<String> orderedUnitIds({ArenaLayout layout = kArenaLayout}) =>
      <String>[
        for (final FormationSlot slot in slots(layout: layout))
          if (placements[slot] case final String id) id,
      ];

  /// Every slot of a formation grid, front line first, top to bottom.
  static List<FormationSlot> slots({ArenaLayout layout = kArenaLayout}) =>
      <FormationSlot>[
        for (int column = 0; column < layout.columns; column++)
          for (int row = 0; row < layout.rows; row++) (row: row, column: column),
      ];

  /// This formation as one URL-safe token, so a composed party is a link you
  /// can share exactly as `/battle` already is.
  String encode() => <String>[
        for (final FormationSlot slot in slots())
          if (placements[slot] case final String id)
            <String>[id, '${slot.row}', '${slot.column}']
                .join(_fieldSeparator),
      ].join(_entrySeparator);

  /// Reads back what [encode] wrote.
  ///
  /// Lenient on purpose: a hand-edited or stale link drops the entries it
  /// cannot read rather than failing, because the caller can tell an empty
  /// formation from a broken one and has somewhere sensible to fall back to.
  /// Unit ids are not checked against any catalogue here — this type does not
  /// know what units exist, and whoever spawns the party does.
  static PartyFormation decode(
    String? encoded, {
    ArenaLayout layout = kArenaLayout,
  }) {
    if (encoded == null || encoded.isEmpty) {
      return const PartyFormation.empty();
    }
    final Map<FormationSlot, String> placements = <FormationSlot, String>{};
    for (final String entry in encoded.split(_entrySeparator)) {
      final List<String> fields = entry.split(_fieldSeparator);
      if (fields.length != 3) {
        continue;
      }
      final String id = fields[0];
      final int? row = int.tryParse(fields[1]);
      final int? column = int.tryParse(fields[2]);
      if (id.isEmpty ||
          row == null ||
          column == null ||
          row < 0 ||
          row >= layout.rows ||
          column < 0 ||
          column >= layout.columns) {
        continue;
      }
      final FormationSlot slot = (row: row, column: column);
      // First writer wins for both a slot and a unit, so a malformed link
      // cannot produce a unit standing in two places.
      if (placements.containsKey(slot) || placements.containsValue(id)) {
        continue;
      }
      placements[slot] = id;
    }
    return PartyFormation(placements);
  }

  @override
  List<Object?> get props => <Object?>[placements];
}
