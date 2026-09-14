import '../../../core/domain/definition_index.dart';
import '../../../core/domain/item.dart';
import '../../../core/domain/stat.dart';
import '../../battle/domain/skill.dart';
import '../../battle/domain/unit_blueprint.dart';
import 'member.dart';
import 'member_condition.dart';
import 'roster.dart';

/// The one place a guild member becomes something that can fight.
///
/// Above this line a member is ids and numbers and knows nothing about
/// combat; below it a [UnitBlueprint] is content and knows nothing about
/// guilds. Dispatch is the seam, so this is where the ids a member carries
/// turn back into definitions — and where an id that names nothing is caught,
/// with the id in the message, rather than becoming a member who mysteriously
/// cannot attack.
///
/// What crosses the seam: the member's base numbers, their gear, their
/// rotation, and their condition as modifiers. What does not: morale, fatigue,
/// loyalty, level, experience and traits, none of which the fight has any
/// business knowing about. It sees a unit with numbers.
class Deployment {
  const Deployment({required this.skills, required this.items});

  /// Every skill in the game, by id.
  final DefinitionIndex<SkillDefinition> skills;

  /// Every item in the game, by id.
  final DefinitionIndex<ItemDefinition> items;

  /// [member] as a unit ready to be placed in a formation.
  ///
  /// Throws when the member names a skill or item that is not in the content
  /// — a save is allowed to be out of date, but it must be reconciled against
  /// the content before a fight starts, not during one.
  UnitBlueprint deploy(Member member) {
    final List<SkillDefinition> rotation = skills.requireAll(member.skillIds);

    return UnitBlueprint(
      id: member.id,
      name: member.name,
      role: member.role,
      maxHealth:
          member.baseStats[Stat.maxHealth] ?? Stat.maxHealth.defaultValue,
      priority: member.priority,
      // Basics last, so a member's specials are tried first — the same order
      // the party screen's skill picker produces, kept here so a rotation
      // dispatched straight from the roster behaves like one the player built.
      skills: <SkillDefinition>[
        for (final SkillDefinition skill in rotation)
          if (!skill.isBasic) skill,
        for (final SkillDefinition skill in rotation)
          if (skill.isBasic) skill,
      ],
      gear: <ItemDefinition>[
        for (final String itemId in member.gear.values) items.require(itemId),
      ],
      baseStats: member.baseStats,
      modifiers: MemberCondition.modifiersFor(member),
    );
  }

  /// [ids] deployed, in the order given.
  ///
  /// Members the roster does not have are skipped rather than throwing: a
  /// party saved before somebody was dismissed is a party one short, which is
  /// a fight the player can still be shown having. A member who *is* here but
  /// names missing content is still an error — that is a content bug, not a
  /// stale reference.
  List<UnitBlueprint> deployAll(Roster roster, Iterable<String> ids) =>
      <UnitBlueprint>[
        for (final String id in ids)
          if (roster.maybe(id) case final Member member) deploy(member),
      ];
}
