import 'package:flutter_test/flutter_test.dart';
import 'package:guild_overseer/src/core/domain/combat_role.dart';
import 'package:guild_overseer/src/core/domain/definition_index.dart';
import 'package:guild_overseer/src/core/domain/faction.dart';
import 'package:guild_overseer/src/core/domain/item.dart';
import 'package:guild_overseer/src/core/domain/meter.dart';
import 'package:guild_overseer/src/core/domain/stat.dart';
import 'package:guild_overseer/src/core/domain/stat_modifier.dart';
import 'package:guild_overseer/src/core/domain/target_priority.dart';
import 'package:guild_overseer/src/features/battle/data/mock_roster.dart';
import 'package:guild_overseer/src/features/battle/domain/combatant.dart';
import 'package:guild_overseer/src/features/battle/domain/skill.dart';
import 'package:guild_overseer/src/features/battle/domain/unit_blueprint.dart';
import 'package:guild_overseer/src/features/guild/domain/deployment.dart';
import 'package:guild_overseer/src/features/guild/domain/member.dart';
import 'package:guild_overseer/src/features/guild/domain/member_condition.dart';
import 'package:guild_overseer/src/features/guild/domain/roster.dart';

import '../battle/battle_test_fixtures.dart';

/// The seam between the guild and the fight: ids become content here, and this
/// is the only place that can tell a member from a unit.
void main() {
  final Deployment deployment = Deployment(
    skills: DefinitionIndex<SkillDefinition>(
      <SkillDefinition>[basicAttack, heavyAttack],
      idOf: (SkillDefinition skill) => skill.id,
      label: 'skill',
    ),
    items: DefinitionIndex<ItemDefinition>(
      <ItemDefinition>[ironGreatsword, wardensShield],
      idOf: (ItemDefinition item) => item.id,
      label: 'item',
    ),
  );

  Member member({
    double morale = Meter.maximum / 2,
    double fatigue = 0,
    List<String> skillIds = const <String>['basic', 'heavy'],
    Map<GearSlot, String> gear = const <GearSlot, String>{},
  }) =>
      Member(
        id: 'bryn',
        name: 'Bryn',
        role: CombatRole.tank,
        priority: TargetPriority.frontline,
        morale: Meter(morale),
        fatigue: Meter(fatigue),
        baseStats: <Stat, double>{Stat.maxHealth: 200, Stat.attackPower: 20},
        skillIds: skillIds,
        gear: gear,
      );

  group('Deployment', () {
    test('carries who the member is across', () {
      final UnitBlueprint unit = deployment.deploy(member());

      expect(unit.id, 'bryn');
      expect(unit.name, 'Bryn');
      expect(unit.role, CombatRole.tank);
      expect(unit.priority, TargetPriority.frontline);
      expect(unit.maxHealth, 200);
    });

    test('turns skill ids into the rotation, basics last', () {
      final UnitBlueprint unit = deployment.deploy(member());

      expect(
        unit.skills.map((SkillDefinition s) => s.id),
        <String>['heavy', 'basic'],
      );
    });

    test('turns worn ids into gear the spawned unit is wearing', () {
      final UnitBlueprint unit = deployment.deploy(
        member(gear: <GearSlot, String>{GearSlot.chest: 'wardens_shield'}),
      );
      final Combatant spawned =
          unit.spawn(faction: Faction.ally, row: 0, column: 0);

      expect(spawned.gear.itemIn(GearSlot.chest)?.id, 'wardens_shield');
      // The shield's +40 health lands through the stat pipeline, on top of the
      // member's own base rather than the declared default.
      expect(spawned.maxHealth, 240);
    });

    test('base stats beyond health reach the unit', () {
      final Combatant spawned = deployment
          .deploy(member())
          .spawn(faction: Faction.ally, row: 0, column: 0);

      expect(spawned.stats.value(Stat.attackPower), 20);
    });

    test('a member naming a skill that does not exist is caught at dispatch', () {
      expect(
        () => deployment.deploy(member(skillIds: <String>['basic', 'gone'])),
        throwsArgumentError,
      );
    });

    test('a member wearing an item that does not exist is caught too', () {
      expect(
        () => deployment.deploy(
          member(gear: <GearSlot, String>{GearSlot.weapon: 'gone'}),
        ),
        throwsArgumentError,
      );
    });

    group('condition', () {
      test('a member at neutral morale and rested carries nothing', () {
        expect(deployment.deploy(member()).modifiers, isEmpty);
      });

      test('high morale hits harder, and it lands on the unit', () {
        final Combatant spawned = deployment
            .deploy(member(morale: Meter.maximum))
            .spawn(faction: Faction.ally, row: 0, column: 0);

        expect(
          spawned.stats.value(Stat.attackPower),
          closeTo(20 * (1 + MemberCondition.moraleOutputSwing), 1e-9),
        );
      });

      test('low morale hits softer', () {
        final Combatant spawned = deployment
            .deploy(member(morale: Meter.minimum))
            .spawn(faction: Faction.ally, row: 0, column: 0);

        expect(
          spawned.stats.value(Stat.attackPower),
          closeTo(20 * (1 - MemberCondition.moraleOutputSwing), 1e-9),
        );
      });

      test('morale moves healing exactly as far as damage', () {
        final List<StatModifier> modifiers =
            MemberCondition.moraleModifiers(Meter.full);

        expect(
          modifiers.singleWhere((StatModifier m) => m.stat == Stat.healPower).value,
          modifiers
              .singleWhere((StatModifier m) => m.stat == Stat.attackPower)
              .value,
        );
      });

      test('fatigue costs health, in proportion to how tired they are', () {
        final Combatant spawned = deployment
            .deploy(member(fatigue: Meter.maximum / 2))
            .spawn(faction: Faction.ally, row: 0, column: 0);

        expect(
          spawned.maxHealth,
          closeTo(200 * (1 - MemberCondition.fatigueHealthPenalty / 2), 1e-9),
        );
      });

      test('an exhausted member spawns at full health of a lower ceiling', () {
        final Combatant spawned = deployment
            .deploy(member(fatigue: Meter.maximum))
            .spawn(faction: Faction.ally, row: 0, column: 0);

        expect(spawned.health, spawned.maxHealth);
        expect(spawned.healthFraction, 1);
      });
    });

    group('deployAll', () {
      final Roster guild = Roster(<Member>[
        member(),
        Member(id: 'sel', name: 'Sel', role: CombatRole.healer),
      ]);

      test('deploys in the order asked for', () {
        expect(
          deployment
              .deployAll(guild, <String>['sel', 'bryn'])
              .map((UnitBlueprint u) => u.id),
          <String>['sel', 'bryn'],
        );
      });

      test('skips a member who is no longer in the guild', () {
        expect(deployment.deployAll(guild, <String>['gone', 'bryn']).length, 1);
      });
    });
  });
}
