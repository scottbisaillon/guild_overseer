import 'package:flutter_test/flutter_test.dart';
import 'package:guild_overseer/src/core/domain/item.dart';
import 'package:guild_overseer/src/core/domain/stat.dart';
import 'package:guild_overseer/src/core/domain/stat_modifier.dart';
import 'package:guild_overseer/src/core/domain/status.dart';
import 'package:guild_overseer/src/features/battle/domain/combatant.dart';

import 'battle_test_fixtures.dart';

/// Gear, which is the same mechanism as a buff wearing different clothes.
void main() {
  const ModifierSource authored = ModifierSource.item('authored');

  const ItemDefinition sword = ItemDefinition(
    id: 'sword',
    name: 'Sword',
    slot: GearSlot.weapon,
    modifiers: <StatModifier>[
      StatModifier.flat(Stat.attackPower, 5, source: authored),
    ],
  );

  const ItemDefinition betterSword = ItemDefinition(
    id: 'better_sword',
    name: 'Better Sword',
    slot: GearSlot.weapon,
    modifiers: <StatModifier>[
      StatModifier.flat(Stat.attackPower, 12, source: authored),
    ],
  );

  const ItemDefinition breastplate = ItemDefinition(
    id: 'breastplate',
    name: 'Breastplate',
    slot: GearSlot.chest,
    modifiers: <StatModifier>[
      StatModifier.flat(Stat.maxHealth, 100, source: authored),
      StatModifier.increased(Stat.damageTakenMultiplier, -0.2, source: authored),
    ],
  );

  group('Loadout', () {
    test('equipping grants what the item states', () {
      final Combatant hero = unit(id: 'hero');
      expect(hero.stats.value(Stat.attackPower), 10);

      hero.gear.equip(sword);

      expect(hero.stats.value(Stat.attackPower), 15);
      expect(hero.gear.itemIn(GearSlot.weapon), sword);
    });

    test('unequipping takes back exactly what it gave', () {
      final Combatant hero = unit(id: 'hero')..gear.equip(breastplate);
      expect(hero.stats.value(Stat.damageTakenMultiplier), 0.8);

      final ItemDefinition? removed = hero.gear.unequip(GearSlot.chest);

      expect(removed, breastplate);
      expect(hero.stats.value(Stat.damageTakenMultiplier), 1);
      expect(hero.gear.isEmpty, isTrue);
    });

    test('one item per slot: equipping swaps and hands the old one back', () {
      final Combatant hero = unit(id: 'hero')..gear.equip(sword);

      final ItemDefinition? replaced = hero.gear.equip(betterSword);

      expect(replaced, sword);
      expect(hero.stats.value(Stat.attackPower), 22,
          reason: 'the old sword is gone, not stacked with the new one');
      expect(hero.gear.worn, hasLength(1));
    });

    test('different slots coexist', () {
      final Combatant hero = unit(id: 'hero', maxHealth: 200)
        ..gear.equip(sword)
        ..gear.equip(breastplate);

      expect(hero.stats.value(Stat.attackPower), 15);
      expect(hero.maxHealth, 300);
      expect(hero.gear.worn.keys, <GearSlot>{GearSlot.weapon, GearSlot.chest});
    });

    test('unequipping a bare slot is not an error', () {
      final Combatant hero = unit(id: 'hero');

      expect(hero.gear.unequip(GearSlot.trinket), isNull);
      expect(hero.stats.value(Stat.attackPower), 10);
    });

    test('a gear change carries health across as a fraction', () {
      final Combatant hero = unit(id: 'hero', maxHealth: 200);
      hero.applyDamage(100);

      hero.gear.equip(breastplate);
      expect(hero.maxHealth, 300);
      expect(hero.health, 150, reason: 'a breastplate is not a heal');

      hero.gear.unequip(GearSlot.chest);
      expect(hero.health, 100);
      expect(hero.isAlive, isTrue);
    });
  });

  group('gear and buffs are indistinguishable to the maths', () {
    const StatusDefinition blessing = StatusDefinition(
      id: 'blessing',
      name: 'Blessing',
      duration: 10,
      modifiers: <StatModifier>[
        StatModifier.flat(
          Stat.attackPower,
          5,
          source: ModifierSource.status('blessing'),
        ),
      ],
    );

    test('they sum, and each is removed by its own source alone', () {
      final Combatant hero = unit(id: 'hero')..gear.equip(sword);
      hero.statuses.apply(
        blessing,
        sourceId: 'hero',
        sourceName: 'hero',
        statSnapshot: const <Stat, double>{},
      );

      expect(hero.stats.value(Stat.attackPower), 20);

      hero.statuses.remove('blessing');
      expect(hero.stats.value(Stat.attackPower), 15,
          reason: 'the sword is untouched by the blessing ending');

      hero.gear.unequip(GearSlot.weapon);
      expect(hero.stats.value(Stat.attackPower), 10);
    });

    test('a tooltip can say where a number came from', () {
      final Combatant hero = unit(id: 'hero')..gear.equip(sword);
      hero.statuses.apply(
        blessing,
        sourceId: 'hero',
        sourceName: 'hero',
        statSnapshot: const <Stat, double>{},
      );

      expect(
        hero.stats.breakdown(Stat.attackPower).keys,
        <ModifierSource>{
          GearSlot.weapon.source,
          const ModifierSource.status('blessing'),
        },
      );
    });
  });
}
