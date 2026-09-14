import 'package:equatable/equatable.dart';

import '../../../core/domain/combat_role.dart';
import 'member.dart';

/// Everyone in the guild.
///
/// Immutable, keyed by member id, and ordered: every edit hands back a new
/// roster, and the order members were added in is the order they are listed
/// in, so the hall does not reshuffle itself when somebody levels.
///
/// It holds the two rules about membership that must not be re-derived by
/// every caller — ids are unique, and the player character cannot be
/// dismissed — because a rule enforced by the type is a rule the management
/// loop cannot forget on one of its paths.
class Roster extends Equatable {
  factory Roster(Iterable<Member> members) {
    final Map<String, Member> byId = <String, Member>{};
    for (final Member member in members) {
      assert(
        !byId.containsKey(member.id),
        'Two members share the id "${member.id}"; ids must be unique.',
      );
      byId[member.id] = member;
    }
    return Roster._(Map<String, Member>.unmodifiable(byId));
  }

  const Roster._(this._byId);

  const Roster.empty() : _byId = const <String, Member>{};

  final Map<String, Member> _byId;

  /// Everyone, in the order they joined.
  Iterable<Member> get all => _byId.values;

  int get size => _byId.length;

  bool get isEmpty => _byId.isEmpty;

  bool get isNotEmpty => _byId.isNotEmpty;

  Iterable<String> get ids => _byId.keys;

  bool contains(String id) => _byId.containsKey(id);

  /// The member with [id], or null. Absence is an ordinary answer: a party
  /// saved before somebody was dismissed names an id that is no longer here.
  Member? maybe(String id) => _byId[id];

  /// The member with [id]. Throws when there is none — for the paths where a
  /// missing member means the caller has already lost track of something.
  Member require(String id) {
    final Member? found = _byId[id];
    if (found == null) {
      throw ArgumentError.value(id, 'member id', 'Nobody in the guild has it.');
    }
    return found;
  }

  /// Free to be dispatched right now.
  Iterable<Member> get ready => all.where((Member m) => m.isReady);

  Iterable<Member> withRole(CombatRole role) =>
      all.where((Member m) => m.role == role);

  /// The player's own character, or null before one is created.
  Member? get playerCharacter {
    for (final Member member in all) {
      if (member.isPlayerCharacter) {
        return member;
      }
    }
    return null;
  }

  /// [member] added, or replaced where one with the same id is already here.
  ///
  /// One operation for both because every caller that changes a member has the
  /// new value and wants it in: a hire, a level-up and a morale hit all end
  /// the same way, and splitting them would only mean each caller deciding
  /// which it is doing.
  Roster withMember(Member member) => Roster._(
        Map<String, Member>.unmodifiable(
          <String, Member>{..._byId, member.id: member},
        ),
      );

  Roster withMembers(Iterable<Member> members) {
    final Map<String, Member> next = <String, Member>{..._byId};
    for (final Member member in members) {
      next[member.id] = member;
    }
    return Roster._(Map<String, Member>.unmodifiable(next));
  }

  /// The member with [id] put through [change].
  ///
  /// The common edit — "this member, but more tired" — without the caller
  /// looking them up first. Unknown ids are left alone rather than throwing,
  /// so applying a run's results to a roster somebody left during the run is
  /// not a crash.
  Roster updated(String id, Member Function(Member member) change) {
    final Member? current = _byId[id];
    if (current == null) {
      return this;
    }
    return withMember(change(current));
  }

  /// Every member in [ids] put through [change]. How a run's outcome lands on
  /// a whole party at once.
  Roster updatedAll(
    Iterable<String> ids,
    Member Function(Member member) change,
  ) {
    Roster next = this;
    for (final String id in ids) {
      next = next.updated(id, change);
    }
    return next;
  }

  /// [id] dismissed.
  ///
  /// Throws for the player character, who cannot be dismissed — see
  /// [[docs/systems/members]]. That is a programming error rather than a
  /// player-facing refusal: the UI should not offer the button, and the rule
  /// lives here so that it holds on every path that did not think to check.
  Roster without(String id) {
    final Member? leaving = _byId[id];
    if (leaving == null) {
      return this;
    }
    if (leaving.isPlayerCharacter) {
      throw StateError('The player character cannot be dismissed.');
    }
    return Roster._(
      Map<String, Member>.unmodifiable(<String, Member>{
        for (final MapEntry<String, Member> entry in _byId.entries)
          if (entry.key != id) entry.key: entry.value,
      }),
    );
  }

  List<Map<String, Object?>> toJson() =>
      <Map<String, Object?>>[for (final Member member in all) member.toJson()];

  static Roster fromJson(Object? json) => Roster(<Member>[
        if (json case final List<Object?> entries)
          for (final Object? entry in entries)
            if (entry is Map<String, Object?>) Member.fromJson(entry),
      ]);

  @override
  List<Object?> get props => <Object?>[_byId];

  @override
  String toString() => 'Roster(${all.map((Member m) => m.name).join(', ')})';
}
