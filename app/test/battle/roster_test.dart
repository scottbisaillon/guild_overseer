import 'package:flutter_test/flutter_test.dart';
import 'package:guild_overseer/src/core/domain/faction.dart';
import 'package:guild_overseer/src/features/battle/data/mock_roster.dart';
import 'package:guild_overseer/src/features/battle/domain/combatant.dart';
import 'package:guild_overseer/src/features/battle/domain/party_formation.dart';
import 'package:guild_overseer/src/features/battle/domain/party_skills.dart';
import 'package:guild_overseer/src/features/battle/domain/skill.dart';
import 'package:guild_overseer/src/features/battle/domain/unit_blueprint.dart';

/// What the party screen hands the battle is a formation of unit ids, and this
/// is where that becomes a fight. The golden transcript covers the authored
/// party; these cover everything the player can do to it.
void main() {
  List<Combatant> alliesOf(List<Combatant> roster) => roster
      .where((Combatant unit) => unit.faction == Faction.ally)
      .toList(growable: false);

  test('the composed party is who stands on the field, and where', () {
    final PartyFormation party = const PartyFormation.empty()
        .place('ally_fenn', (row: 2, column: 1))
        .place('ally_tovin', (row: 0, column: 0));

    final List<Combatant> allies = alliesOf(buildRoster(party: party));

    expect(
      allies.map((Combatant unit) => unit.id),
      <String>['ally_tovin', 'ally_fenn'],
      reason: 'front line first, top to bottom',
    );
    expect(allies.first.row, 0);
    expect(allies.first.column, 0);
    expect(allies.last.row, 2);
    expect(allies.last.column, 1);
  });

  test('a party of two fights a room of six', () {
    final PartyFormation party = const PartyFormation.empty()
        .place('ally_bramm', (row: 0, column: 0))
        .place('ally_ysolde', (row: 0, column: 1));

    final List<Combatant> roster = buildRoster(party: party);

    expect(alliesOf(roster).length, 2);
    expect(
      roster.where((Combatant unit) => unit.faction == Faction.enemy).length,
      kDungeonUnits.length,
    );
  });

  test('a unit brings its gear, so its stats are what the card promised', () {
    final PartyFormation party =
        const PartyFormation.empty().place('ally_bramm', (row: 0, column: 0));
    final UnitBlueprint bramm = recruitableUnit('ally_bramm')!;

    final Combatant unit = alliesOf(buildRoster(party: party)).single;

    // The shield is worth 40 max health on top of the authored number.
    expect(unit.maxHealth, bramm.maxHealth + 40);
    expect(
      unit.rotation.map((slot) => slot.definition.id),
      bramm.skills.map((skill) => skill.id),
    );
  });

  test('a link naming units that do not exist drops them', () {
    final PartyFormation party = PartyFormation.decode(
      'ally_kessa:0:0,ally_nobody:1:0',
    );

    final List<Combatant> allies = alliesOf(buildRoster(party: party));

    expect(allies.map((Combatant unit) => unit.id), <String>['ally_kessa']);
  });

  test('a party nobody could fight falls back to the authored one', () {
    // An empty ally side would be a fight that is over before it starts, so a
    // stale or emptied link gets the mockup rather than an instant loss.
    final List<Combatant> allies =
        alliesOf(buildRoster(party: PartyFormation.decode('ally_nobody:0:0')));

    expect(
      allies.map((Combatant unit) => unit.id),
      alliesOf(buildMockRoster()).map((Combatant unit) => unit.id),
    );
  });

  group('the skills the player chose', () {
    final PartyFormation party =
        const PartyFormation.empty().place('ally_bramm', (row: 0, column: 0));

    List<String> rotationOf(List<Combatant> roster) => roster.first.rotation
        .map((SkillSlot slot) => slot.definition.id)
        .toList(growable: false);

    test('a unit fights with what it was given, in the order given', () {
      final List<Combatant> allies = alliesOf(buildRoster(
        party: party,
        skills: const PartySkills.empty()
            .withUnit('ally_bramm', <String>['mend', 'cleave']),
      ));

      // The basic attack the unit was authored with stays, and stays last.
      expect(rotationOf(allies), <String>['mend', 'cleave', 'strike']);
    });

    test('a unit nobody chose for keeps the skills it was authored with', () {
      final List<Combatant> allies = alliesOf(buildRoster(
        party: party,
        skills: const PartySkills.empty()
            .withUnit('ally_fenn', <String>['mend']),
      ));

      expect(rotationOf(allies), <String>['fortify', 'shield_slam', 'strike']);
    });

    test('a unit can give up its specials and still have something to do', () {
      final List<Combatant> allies = alliesOf(buildRoster(
        party: party,
        skills: const PartySkills.empty()
            .withUnit('ally_bramm', <String>[]),
      ));

      expect(rotationOf(allies), <String>['strike']);
    });

    test('a link naming skills that do not exist drops them', () {
      final List<Combatant> allies = alliesOf(buildRoster(
        party: party,
        skills: PartySkills.decode('ally_bramm:cleave.sorcery'),
      ));

      expect(rotationOf(allies), <String>['cleave', 'strike']);
    });

    test('every skill a unit was authored with can be chosen again', () {
      for (final UnitBlueprint unit in kRecruitableUnits) {
        for (final SkillDefinition skill in unit.chosenSkills) {
          expect(
            poolSkill(skill.id),
            isNotNull,
            reason: '${unit.name} starts with ${skill.name}, which the pool '
                'does not offer — resetting would be a one-way trip',
          );
        }
        expect(
          unit.basicSkills,
          isNotEmpty,
          reason: '${unit.name} would stand still with an empty rotation',
        );
      }
    });

    test('every pool skill has an id of its own', () {
      final Set<String> ids =
          kSkillPool.map((SkillDefinition skill) => skill.id).toSet();

      expect(ids.length, kSkillPool.length);
    });
  });

  test('every recruitable unit has an id of its own', () {
    final Set<String> ids =
        kRecruitableUnits.map((UnitBlueprint unit) => unit.id).toSet();

    expect(ids.length, kRecruitableUnits.length);
  });

  test('the default party fills the formation it is fought in', () {
    expect(kDefaultParty.size, 6);
    for (final String id in kDefaultParty.orderedUnitIds()) {
      expect(recruitableUnit(id), isNotNull, reason: '$id is not recruitable');
    }
  });

  test('a fresh roster is built each time, never shared between fights', () {
    final List<Combatant> first = buildMockRoster();
    final List<Combatant> second = buildMockRoster();

    first.first.applyDamage(100);

    expect(second.first.health, second.first.maxHealth);
  });
}
