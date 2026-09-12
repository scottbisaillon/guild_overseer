import 'package:flutter_test/flutter_test.dart';
import 'package:guild_overseer/src/core/domain/combat_role.dart';
import 'package:guild_overseer/src/core/domain/faction.dart';
import 'package:guild_overseer/src/features/battle/domain/combatant.dart';
import 'package:guild_overseer/src/features/battle/domain/rotation.dart';
import 'package:guild_overseer/src/features/battle/domain/skill.dart';

import 'battle_test_fixtures.dart';

void main() {
  group('selectSkill', () {
    test('nothing fires while the global cooldown is running', () {
      final Combatant hero = unit(
        id: 'hero',
        skills: const <SkillDefinition>[heavyAttack, basicAttack],
      )..startGlobalCooldown();
      final Combatant target = unit(id: 'target', faction: Faction.enemy);

      expect(
        selectSkill(
          unit: hero,
          currentTarget: target,
          units: <Combatant>[hero, target],
        ),
        isNull,
      );
    });

    test('the highest-priority ready skill wins', () {
      final Combatant hero = unit(
        id: 'hero',
        skills: const <SkillDefinition>[heavyAttack, basicAttack],
      );
      final Combatant target = unit(id: 'target', faction: Faction.enemy);

      final RotationDecision? decision = selectSkill(
        unit: hero,
        currentTarget: target,
        units: <Combatant>[hero, target],
      );

      expect(decision?.skill.id, 'heavy');
    });

    test('the basic attack fills the gap while the special cools down', () {
      final Combatant hero = unit(
        id: 'hero',
        skills: const <SkillDefinition>[heavyAttack, basicAttack],
      );
      final Combatant target = unit(id: 'target', faction: Faction.enemy);
      final List<Combatant> units = <Combatant>[hero, target];

      // Beat one: the heavy attack fires and both cooldowns start.
      selectSkill(unit: hero, currentTarget: target, units: units)!
          .slot
          .trigger();
      hero.startGlobalCooldown();

      // One second later the global cooldown is up but the heavy attack, on a
      // two second cooldown, is not.
      hero.tickCooldowns(1.0);

      expect(
        selectSkill(unit: hero, currentTarget: target, units: units)?.skill.id,
        'basic',
      );

      // One more second and the heavy attack comes back around.
      hero.tickCooldowns(1.0);

      expect(
        selectSkill(unit: hero, currentTarget: target, units: units)?.skill.id,
        'heavy',
      );
    });

    test('a skill with nothing to hit is skipped, not stalled on', () {
      final Combatant healer = unit(
        id: 'healer',
        role: CombatRole.healer,
        skills: const <SkillDefinition>[healSkill, basicAttack],
      );
      final Combatant friend = unit(id: 'friend', row: 1);
      final Combatant target = unit(id: 'target', faction: Faction.enemy);
      final List<Combatant> units = <Combatant>[healer, friend, target];

      expect(
        selectSkill(unit: healer, currentTarget: target, units: units)
            ?.skill
            .id,
        'basic',
        reason: 'nobody is wounded, so the heal cannot resolve',
      );

      friend.applyDamage(50);

      expect(
        selectSkill(unit: healer, currentTarget: target, units: units)
            ?.skill
            .id,
        'heal',
      );
    });

    test('the dead do not act', () {
      final Combatant hero = unit(id: 'hero')..applyDamage(999);
      final Combatant target = unit(id: 'target', faction: Faction.enemy);

      expect(
        selectSkill(
          unit: hero,
          currentTarget: target,
          units: <Combatant>[hero, target],
        ),
        isNull,
      );
    });
  });
}
