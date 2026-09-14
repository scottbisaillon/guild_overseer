import 'package:flutter_test/flutter_test.dart';
import 'package:guild_overseer/src/core/domain/combat_role.dart';
import 'package:guild_overseer/src/core/domain/faction.dart';
import 'package:guild_overseer/src/core/domain/target_priority.dart';
import 'package:guild_overseer/src/features/battle/domain/arena_layout.dart';
import 'package:guild_overseer/src/features/battle/domain/combatant.dart';
import 'package:guild_overseer/src/core/domain/target_selector.dart';
import 'package:guild_overseer/src/features/battle/domain/targeting.dart';

import 'battle_test_fixtures.dart';

void main() {
  const ArenaLayout layout = kArenaLayout;

  group('selectTarget', () {
    test('picks the nearest opponent', () {
      final Combatant hero = unit(id: 'hero', row: 0, column: 0);
      final Combatant near =
          unit(id: 'near', faction: Faction.enemy, row: 0, column: 0);
      final Combatant far =
          unit(id: 'far', faction: Faction.enemy, row: 2, column: 1);

      final Combatant? target = selectTarget(
        unit: hero,
        candidates: <Combatant>[hero, near, far],
        layout: layout,
      );

      expect(target?.id, 'near');
    });

    test('never targets itself or an ally', () {
      final Combatant hero = unit(id: 'hero');
      final Combatant friend = unit(id: 'friend', row: 1);

      final Combatant? target = selectTarget(
        unit: hero,
        candidates: <Combatant>[hero, friend],
        layout: layout,
      );

      expect(target, isNull);
    });

    test('ignores the dead', () {
      final Combatant hero = unit(id: 'hero', row: 0, column: 0);
      final Combatant corpse =
          unit(id: 'corpse', faction: Faction.enemy, row: 0, column: 0)
            ..applyDamage(999);
      final Combatant living =
          unit(id: 'living', faction: Faction.enemy, row: 2, column: 1);

      final Combatant? target = selectTarget(
        unit: hero,
        candidates: <Combatant>[hero, corpse, living],
        layout: layout,
      );

      expect(target?.id, 'living');
    });

    test('weakest prefers the lowest health fraction over distance', () {
      final Combatant archer = unit(
        id: 'archer',
        priority: TargetPriority.weakest,
        row: 0,
        column: 1,
      );
      final Combatant healthy =
          unit(id: 'healthy', faction: Faction.enemy, row: 0, column: 0);
      final Combatant wounded =
          unit(id: 'wounded', faction: Faction.enemy, row: 2, column: 1)
            ..applyDamage(70);

      final Combatant? target = selectTarget(
        unit: archer,
        candidates: <Combatant>[archer, healthy, wounded],
        layout: layout,
      );

      expect(target?.id, 'wounded');
    });

    test('healerFirst hunts the healer, then falls back to distance', () {
      final Combatant hexweaver = unit(
        id: 'hexweaver',
        faction: Faction.enemy,
        priority: TargetPriority.healerFirst,
        row: 2,
        column: 1,
      );
      final Combatant frontliner = unit(id: 'frontliner', row: 2, column: 0);
      final Combatant healer =
          unit(id: 'healer', role: CombatRole.healer, row: 0, column: 1);

      expect(
        selectTarget(
          unit: hexweaver,
          candidates: <Combatant>[hexweaver, frontliner, healer],
          layout: layout,
        )?.id,
        'healer',
      );

      healer.applyDamage(999);

      expect(
        selectTarget(
          unit: hexweaver,
          candidates: <Combatant>[hexweaver, frontliner, healer],
          layout: layout,
        )?.id,
        'frontliner',
      );
    });

    test('frontline prefers column 0, backline prefers the far column', () {
      final Combatant front = unit(
        id: 'front',
        priority: TargetPriority.frontline,
      );
      final Combatant back = unit(
        id: 'back',
        priority: TargetPriority.backline,
      );
      final List<Combatant> candidates = <Combatant>[
        front,
        back,
        unit(id: 'enemy_front', faction: Faction.enemy, row: 1, column: 0),
        unit(id: 'enemy_back', faction: Faction.enemy, row: 1, column: 1),
      ];

      expect(
        selectTarget(unit: front, candidates: candidates, layout: layout)?.id,
        'enemy_front',
      );
      expect(
        selectTarget(unit: back, candidates: candidates, layout: layout)?.id,
        'enemy_back',
      );
    });
  });

  group('resolveTargets', () {
    test('a column skill hits every living unit in the target column', () {
      final Combatant hero = unit(id: 'hero');
      final List<Combatant> enemies = <Combatant>[
        unit(id: 'e0', faction: Faction.enemy, row: 0, column: 0),
        unit(id: 'e1', faction: Faction.enemy, row: 1, column: 0),
        unit(id: 'e2', faction: Faction.enemy, row: 2, column: 1),
      ];

      final List<Combatant> targets = resolveTargets(
        selector: TargetSelector.currentEnemyColumn,
        caster: hero,
        currentTarget: enemies.first,
        units: <Combatant>[hero, ...enemies],
        layout: kArenaLayout,
      );

      expect(
        targets.map((Combatant c) => c.id),
        <String>['e0', 'e1'],
      );
    });

    test('a heal resolves to nothing while the side is at full health', () {
      final Combatant healer = unit(id: 'healer', role: CombatRole.healer);
      final Combatant friend = unit(id: 'friend', row: 1);

      expect(
        resolveTargets(
          selector: TargetSelector.mostWoundedAlly,
          caster: healer,
          currentTarget: null,
          units: <Combatant>[healer, friend],
          layout: kArenaLayout,
        ),
        isEmpty,
      );

      friend.applyDamage(40);

      expect(
        resolveTargets(
          selector: TargetSelector.mostWoundedAlly,
          caster: healer,
          currentTarget: null,
          units: <Combatant>[healer, friend],
          layout: kArenaLayout,
        ).single.id,
        'friend',
      );
    });

    test('a row skill hits the target and whoever stands behind it', () {
      final Combatant hero = unit(id: 'hero');
      final List<Combatant> enemies = <Combatant>[
        unit(id: 'front', faction: Faction.enemy, row: 1, column: 0),
        unit(id: 'behind', faction: Faction.enemy, row: 1, column: 1),
        unit(id: 'elsewhere', faction: Faction.enemy, row: 2, column: 1),
      ];

      final List<Combatant> targets = resolveTargets(
        selector: TargetSelector.currentEnemyRow,
        caster: hero,
        currentTarget: enemies.first,
        units: <Combatant>[hero, ...enemies],
        layout: kArenaLayout,
      );

      expect(
        targets.map((Combatant c) => c.id),
        <String>['front', 'behind'],
      );
    });

    test('an area skill hits the whole opposing side and nobody else', () {
      final Combatant hero = unit(id: 'hero');
      final Combatant friend = unit(id: 'friend', row: 1);
      final List<Combatant> enemies = <Combatant>[
        unit(id: 'e0', faction: Faction.enemy, row: 0, column: 0),
        unit(id: 'e1', faction: Faction.enemy, row: 2, column: 1),
      ];

      final List<Combatant> targets = resolveTargets(
        selector: TargetSelector.allEnemies,
        caster: hero,
        currentTarget: null,
        units: <Combatant>[hero, friend, ...enemies],
        layout: kArenaLayout,
      );

      expect(targets.map((Combatant c) => c.id), <String>['e0', 'e1']);
    });

    test('a single-target skill needs a living target', () {
      final Combatant hero = unit(id: 'hero');
      final Combatant corpse = unit(id: 'corpse', faction: Faction.enemy)
        ..applyDamage(999);

      expect(
        resolveTargets(
          selector: TargetSelector.currentEnemy,
          caster: hero,
          currentTarget: corpse,
          units: <Combatant>[hero, corpse],
          layout: kArenaLayout,
        ),
        isEmpty,
      );
    });
  });
}
