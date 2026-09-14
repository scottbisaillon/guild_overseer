import '../../../core/domain/combat_role.dart';
import '../../../core/domain/faction.dart';
import '../../../core/domain/skill_effect.dart';
import '../../../core/domain/target_priority.dart';
import 'arena_layout.dart';
import 'combatant.dart';
import 'party_formation.dart';
import 'skill.dart';
import 'targeting.dart';

/// Where a skill lands, as cells of the two formations.
///
/// What a skill covers is a property of its targeting, and the party screen
/// wants to show it before a fight exists to show it in. The honest way to
/// answer is to ask the same resolver the fight asks — see [reachOf] — so the
/// preview cannot drift from the rules the way a second reading of the
/// selector would.
class SkillReach {
  const SkillReach({
    required this.caster,
    required this.allies,
    required this.enemies,
  });

  /// Where the unit doing this is standing, so a preview can show the blow
  /// leaving from somewhere.
  final FormationSlot caster;

  /// Cells of the caster's own formation this lands on.
  final Set<FormationSlot> allies;

  /// Cells of the opposing formation this lands on.
  final Set<FormationSlot> enemies;

  int get cellCount => allies.length + enemies.length;

  /// More than one cell: an area skill, whatever shape the area is.
  bool get coversSeveral => cellCount > 1;

  bool covers(Faction faction, FormationSlot slot) => faction == Faction.ally
      ? allies.contains(slot)
      : enemies.contains(slot);
}

/// Where [skill] lands when everything it could want is there to be found.
///
/// Resolved against a reference fight: two full formations, everyone wounded,
/// the caster in the middle of its own front line and locked onto the enemy
/// opposite. That is a picture of the skill's reach rather than a promise about
/// one fight — a heal shows who it could mend, and a rank-wide blow shows the
/// whole rank even though a real one may find two of the three already dead.
///
/// Everyone is wounded on purpose: filters like "only the hurt" would
/// otherwise resolve to nobody and a heal would preview as reaching nothing.
SkillReach reachOf(SkillDefinition skill, {ArenaLayout layout = kArenaLayout}) {
  final Map<Faction, Map<FormationSlot, Combatant>> formations =
      <Faction, Map<FormationSlot, Combatant>>{
    for (final Faction faction in Faction.values)
      faction: <FormationSlot, Combatant>{
        for (final FormationSlot slot in PartyFormation.slots(layout: layout))
          slot: _reference(faction, slot),
      },
  };

  const FormationSlot middleOfTheFrontLine = (row: 1, column: 0);
  final Combatant caster = formations[Faction.ally]![middleOfTheFrontLine]!;
  final Combatant target = formations[Faction.enemy]![middleOfTheFrontLine]!;
  final List<Combatant> units = <Combatant>[
    for (final Map<FormationSlot, Combatant> side in formations.values)
      ...side.values,
  ];

  final Set<FormationSlot> allies = <FormationSlot>{};
  final Set<FormationSlot> enemies = <FormationSlot>{};
  for (final EffectSpec spec in skill.effects) {
    for (final Combatant unit in resolveTargets(
      selector: spec.selector,
      caster: caster,
      currentTarget: target,
      units: units,
      layout: layout,
    )) {
      final FormationSlot slot = (row: unit.row, column: unit.column);
      (unit.faction == Faction.ally ? allies : enemies).add(slot);
    }
  }

  return SkillReach(
    caster: middleOfTheFrontLine,
    allies: allies,
    enemies: enemies,
  );
}

/// A stand-in unit: somebody to stand in a cell and be selected.
///
/// Wounded, so that a heal has something to mend, and so an execute threshold
/// has somebody low enough to finish.
Combatant _reference(Faction faction, FormationSlot slot) {
  final Combatant unit = Combatant(
    id: '${faction.name}_${slot.row}_${slot.column}',
    name: 'reference',
    faction: faction,
    role: CombatRole.meleeDps,
    row: slot.row,
    column: slot.column,
    maxHealth: 100,
    priority: TargetPriority.nearest,
    skills: const <SkillDefinition>[],
  );
  unit.applyDamage(90);
  return unit;
}
