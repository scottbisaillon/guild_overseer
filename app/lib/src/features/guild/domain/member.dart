import 'package:equatable/equatable.dart';

import '../../../core/domain/combat_role.dart';
import '../../../core/domain/item.dart';
import '../../../core/domain/meter.dart';
import '../../../core/domain/stat.dart';
import '../../../core/domain/target_priority.dart';
import 'experience_curve.dart';

/// What a member is doing, and so whether they can be sent anywhere.
///
/// One axis rather than a set of booleans, because the states are exclusive:
/// a member resting is not also on a run. The management loop owns the
/// transitions between them; this only says what the states are.
enum MemberAvailability {
  /// Idle in the hall and free to be dispatched.
  ready('Ready'),

  /// Out on a run. Cannot join a second party until it returns.
  onRun('On run'),

  /// Recovering fatigue in the hall. Dispatchable, at a cost — the loop
  /// decides whether to allow it, and this says why it would hurt.
  resting('Resting'),

  /// Hurt badly enough to be out of action until healed.
  injured('Injured');

  const MemberAvailability(this.label);

  /// Human readable name used by the HUD.
  final String label;
}

/// One person in the guild.
///
/// The unit the entire management loop moves around: recruited, dispatched,
/// fatigued, paid, levelled and occasionally lost. A value with `copyWith`
/// rather than a mutable object, so "what a run did to the party" is a
/// comparison between two rosters rather than a diary somebody has to keep.
///
/// Everything here is either a plain number or an **id**. A member wears the
/// id of a sword, not the sword; knows the ids of its skills, not the skills.
/// That is what keeps a save a list of ids instead of a copy of the game's
/// content, and it is why nothing in this file imports the battle layer. Ids
/// become definitions at exactly one point — `deploy`, in `deployment.dart` —
/// and that is also where an unknown one is caught.
///
/// A member is not a combatant and never becomes one: a fight spawns its own.
class Member extends Equatable {
  const Member({
    required this.id,
    required this.name,
    required this.role,
    this.experience = 0,
    this.morale = Meter.half,
    this.loyalty = Meter.half,
    this.fatigue = Meter.empty,
    this.availability = MemberAvailability.ready,
    this.priority = TargetPriority.nearest,
    this.isPlayerCharacter = false,
    this.baseStats = const <Stat, double>{},
    this.skillIds = const <String>[],
    this.gear = const <GearSlot, String>{},
    this.traitIds = const <String>[],
  });

  /// A member as the tavern hands them over: at [level], rested, and neither
  /// loyal nor disloyal yet.
  factory Member.recruit({
    required String id,
    required String name,
    required CombatRole role,
    int level = 1,
    TargetPriority priority = TargetPriority.nearest,
    bool isPlayerCharacter = false,
    Map<Stat, double> baseStats = const <Stat, double>{},
    List<String> skillIds = const <String>[],
    List<String> traitIds = const <String>[],
  }) =>
      Member(
        id: id,
        name: name,
        role: role,
        experience: ExperienceCurve.totalFor(level),
        priority: priority,
        isPlayerCharacter: isPlayerCharacter,
        baseStats: baseStats,
        skillIds: skillIds,
        traitIds: traitIds,
      );

  /// Stable for the life of the save. Parties, active runs and loot
  /// assignments all refer to a member by this and never by name — two
  /// recruits can share a name, and a rename must not orphan anything.
  final String id;

  final String name;

  /// What this member does in a fight. Stands in for the class system until
  /// it exists: the five classes in [[docs/early-game]] are these five roles,
  /// and a class will carry one rather than replace it.
  final CombatRole role;

  /// Total earned, never spent. [level] is read off it.
  final int experience;

  /// Performance. Drops on a wipe, rises on a clear.
  final Meter morale;

  /// Risk of leaving. Low for long enough and a member walks.
  final Meter loyalty;

  /// Accumulated by consecutive runs. Cleared by rest.
  final Meter fatigue;

  final MemberAvailability availability;

  /// How this member picks an opponent, until the rotation editor lets the
  /// player set it per skill.
  final TargetPriority priority;

  /// The player's own character. Created at game start, never dismissed, and
  /// otherwise treated exactly like anyone else — the flag exists because the
  /// run mode depends on whether this member is in the party, not because the
  /// systems need to tell them apart.
  final bool isPlayerCharacter;

  /// The numbers this member was rolled with, before gear and condition.
  ///
  /// Only the stats that differ from their declared defaults need an entry.
  /// Level does not scale these yet: what a level is worth in stats is a
  /// balance decision that belongs with the class table, and inventing a
  /// growth curve here would be a number nobody chose.
  final Map<Stat, double> baseStats;

  /// The rotation, in priority order, as ids. Includes the basic attack —
  /// `deploy` sorts it last where the fight expects it.
  final List<String> skillIds;

  /// Worn gear, as item ids. One item per slot is the rule the slot itself
  /// enforces, and a bare slot is an absent entry rather than a null.
  final Map<GearSlot, String> gear;

  /// Personality, as trait ids. Nothing reads these yet; they are here so a
  /// recruit rolled today is still the same person once traits land.
  final List<String> traitIds;

  /// Read off [experience] rather than stored — see [ExperienceCurve].
  int get level => ExperienceCurve.levelFor(experience);

  /// How far through the current level, 0.0 to 1.0. For the roster bar.
  double get levelProgress => ExperienceCurve.progressWithin(experience);

  bool get isReady => availability == MemberAvailability.ready;

  /// The item worn in [slot], as an id, or null when the slot is bare.
  String? gearIn(GearSlot slot) => gear[slot];

  /// This member [amount] experience richer. Compare [level] before and after
  /// to see whether that bought a level — the loop decides what a level-up
  /// announces, and there is nothing to announce until it does.
  Member gainExperience(int amount) {
    assert(amount >= 0, 'Experience is never taken away.');
    return copyWith(experience: experience + amount);
  }

  /// Condition changes, clamped by the meters themselves. Negative drains.
  Member adjustMorale(double delta) => copyWith(morale: morale.adjustedBy(delta));

  Member adjustLoyalty(double delta) =>
      copyWith(loyalty: loyalty.adjustedBy(delta));

  Member adjustFatigue(double delta) =>
      copyWith(fatigue: fatigue.adjustedBy(delta));

  /// Puts [itemId] in [slot], replacing whatever was there. The item that came
  /// off is not returned — the caller knows what it was from [gearIn], and
  /// where it goes back to is the stash's business, not the member's.
  Member equip(GearSlot slot, String itemId) => copyWith(
        gear: <GearSlot, String>{...gear, slot: itemId},
      );

  Member unequip(GearSlot slot) => copyWith(
        gear: <GearSlot, String>{
          for (final MapEntry<GearSlot, String> worn in gear.entries)
            if (worn.key != slot) worn.key: worn.value,
        },
      );

  Member withSkills(List<String> ids) => copyWith(skillIds: ids);

  Member withAvailability(MemberAvailability next) =>
      copyWith(availability: next);

  Member copyWith({
    String? name,
    CombatRole? role,
    int? experience,
    Meter? morale,
    Meter? loyalty,
    Meter? fatigue,
    MemberAvailability? availability,
    TargetPriority? priority,
    Map<Stat, double>? baseStats,
    List<String>? skillIds,
    Map<GearSlot, String>? gear,
    List<String>? traitIds,
  }) =>
      Member(
        id: id,
        name: name ?? this.name,
        role: role ?? this.role,
        experience: experience ?? this.experience,
        morale: morale ?? this.morale,
        loyalty: loyalty ?? this.loyalty,
        fatigue: fatigue ?? this.fatigue,
        availability: availability ?? this.availability,
        priority: priority ?? this.priority,
        isPlayerCharacter: isPlayerCharacter,
        baseStats: baseStats ?? this.baseStats,
        skillIds: skillIds ?? this.skillIds,
        gear: gear ?? this.gear,
        traitIds: traitIds ?? this.traitIds,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'name': name,
        'role': role.name,
        'experience': experience,
        'morale': morale.toJson(),
        'loyalty': loyalty.toJson(),
        'fatigue': fatigue.toJson(),
        'availability': availability.name,
        'priority': priority.name,
        'isPlayerCharacter': isPlayerCharacter,
        'baseStats': <String, double>{
          for (final MapEntry<Stat, double> stat in baseStats.entries)
            stat.key.name: stat.value,
        },
        'skillIds': skillIds,
        'gear': <String, String>{
          for (final MapEntry<GearSlot, String> worn in gear.entries)
            worn.key.name: worn.value,
        },
        'traitIds': traitIds,
      };

  /// Rebuilds a member from a save.
  ///
  /// Anything unreadable falls back to the default rather than throwing: a
  /// member is player progress, and losing the whole roster because one enum
  /// was renamed between versions is not a trade worth making. Content ids are
  /// kept as written and validated later, at `deploy`, where a missing one can
  /// be reported against the content that is actually loaded.
  static Member fromJson(Map<String, Object?> json) => Member(
        id: json['id']! as String,
        name: json['name'] as String? ?? 'Unnamed',
        role: _byName(CombatRole.values, json['role'], CombatRole.meleeDps),
        experience: (json['experience'] as num?)?.toInt() ?? 0,
        morale: Meter.fromJson(json['morale']),
        loyalty: Meter.fromJson(json['loyalty']),
        fatigue: Meter.fromJson(json['fatigue']),
        availability: _byName(
          MemberAvailability.values,
          json['availability'],
          MemberAvailability.ready,
        ),
        priority: _byName(
          TargetPriority.values,
          json['priority'],
          TargetPriority.nearest,
        ),
        isPlayerCharacter: json['isPlayerCharacter'] as bool? ?? false,
        baseStats: <Stat, double>{
          if (json['baseStats'] case final Map<Object?, Object?> stats)
            for (final MapEntry<Object?, Object?> stat in stats.entries)
              if (_maybeByName(Stat.values, stat.key) case final Stat known)
                known: (stat.value as num).toDouble(),
        },
        skillIds: _stringList(json['skillIds']),
        gear: <GearSlot, String>{
          if (json['gear'] case final Map<Object?, Object?> worn)
            for (final MapEntry<Object?, Object?> slot in worn.entries)
              if (_maybeByName(GearSlot.values, slot.key) case final GearSlot s)
                s: slot.value! as String,
        },
        traitIds: _stringList(json['traitIds']),
      );

  static List<String> _stringList(Object? json) => <String>[
        if (json case final List<Object?> entries)
          for (final Object? entry in entries)
            if (entry is String) entry,
      ];

  static T _byName<T extends Enum>(List<T> values, Object? name, T fallback) =>
      _maybeByName(values, name) ?? fallback;

  static T? _maybeByName<T extends Enum>(List<T> values, Object? name) {
    for (final T value in values) {
      if (value.name == name) {
        return value;
      }
    }
    return null;
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        name,
        role,
        experience,
        morale,
        loyalty,
        fatigue,
        availability,
        priority,
        isPlayerCharacter,
        baseStats,
        skillIds,
        gear,
        traitIds,
      ];

  @override
  String toString() => '$name (${role.label}, level $level)';
}
