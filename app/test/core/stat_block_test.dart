import 'package:flutter_test/flutter_test.dart';
import 'package:guild_overseer/src/core/domain/stat.dart';
import 'package:guild_overseer/src/core/domain/stat_block.dart';
import 'package:guild_overseer/src/core/domain/stat_modifier.dart';

/// The pipeline every source of power in the game funnels through, so the
/// arithmetic is worth pinning precisely. If these stop holding, gear and
/// buffs stop being comparable to each other.
void main() {
  const ModifierSource sword = ModifierSource.item('weapon');
  const ModifierSource chest = ModifierSource.item('chest');
  const ModifierSource warCry = ModifierSource.status('war_cry');

  group('StatBlock', () {
    test('an unmodified stat is its base', () {
      final StatBlock stats =
          StatBlock(<Stat, double>{Stat.attackPower: 40});

      expect(stats.value(Stat.attackPower), 40);
      expect(stats.base(Stat.attackPower), 40);
    });

    test('a stat with no authored base falls back to the declared default', () {
      final StatBlock stats = StatBlock();

      expect(stats.value(Stat.attackPower), Stat.attackPower.defaultValue);
    });

    test('flat modifiers sum', () {
      final StatBlock stats = StatBlock(<Stat, double>{Stat.attackPower: 40})
        ..add(const StatModifier.flat(Stat.attackPower, 12, source: sword))
        ..add(const StatModifier.flat(Stat.attackPower, 8, source: chest));

      expect(stats.value(Stat.attackPower), 60);
    });

    test('increases sum before they are applied, so two 10% give 20%', () {
      final StatBlock stats = StatBlock(<Stat, double>{Stat.attackPower: 100})
        ..add(const StatModifier.increased(Stat.attackPower, 0.1, source: sword))
        ..add(const StatModifier.increased(Stat.attackPower, 0.1, source: chest));

      expect(stats.value(Stat.attackPower), closeTo(120, 1e-9));
    });

    test('more modifiers multiply, so two 10% give 21%', () {
      final StatBlock stats = StatBlock(<Stat, double>{Stat.attackPower: 100})
        ..add(const StatModifier.more(Stat.attackPower, 0.1, source: sword))
        ..add(const StatModifier.more(Stat.attackPower, 0.1, source: chest));

      expect(stats.value(Stat.attackPower), closeTo(121, 1e-9));
    });

    test('the whole pipeline runs flat, then increased, then more', () {
      // (100 + 20) * (1 + 0.5) * 1.2 = 216
      final StatBlock stats = StatBlock(<Stat, double>{Stat.attackPower: 100})
        ..add(const StatModifier.flat(Stat.attackPower, 20, source: sword))
        ..add(const StatModifier.increased(Stat.attackPower, 0.5, source: chest))
        ..add(const StatModifier.more(Stat.attackPower, 0.2, source: warCry));

      expect(stats.value(Stat.attackPower), closeTo(216, 1e-9));
    });

    test('the order modifiers arrive in does not change the result', () {
      const List<StatModifier> all = <StatModifier>[
        StatModifier.more(Stat.attackPower, 0.2, source: warCry),
        StatModifier.flat(Stat.attackPower, 20, source: sword),
        StatModifier.increased(Stat.attackPower, 0.5, source: chest),
      ];

      final StatBlock forwards =
          StatBlock(<Stat, double>{Stat.attackPower: 100})..addAll(all);
      final StatBlock backwards =
          StatBlock(<Stat, double>{Stat.attackPower: 100})
            ..addAll(all.reversed);

      expect(forwards.value(Stat.attackPower),
          backwards.value(Stat.attackPower));
    });

    test('modifiers only touch the stat they name', () {
      final StatBlock stats = StatBlock(<Stat, double>{
        Stat.attackPower: 40,
        Stat.healPower: 40,
      })
        ..add(const StatModifier.flat(Stat.attackPower, 20, source: sword));

      expect(stats.value(Stat.attackPower), 60);
      expect(stats.value(Stat.healPower), 40);
    });

    test('removing a source removes exactly what it granted', () {
      final StatBlock stats = StatBlock(<Stat, double>{Stat.attackPower: 100})
        ..add(const StatModifier.flat(Stat.attackPower, 20, source: sword))
        ..add(const StatModifier.flat(Stat.attackPower, 5, source: chest));

      expect(stats.removeBySource(sword), 1);

      expect(stats.value(Stat.attackPower), 105);
      expect(stats.hasSource(sword), isFalse);
      expect(stats.hasSource(chest), isTrue);
    });

    test('removing every source returns the stat to its base', () {
      final StatBlock stats = StatBlock(<Stat, double>{Stat.attackPower: 100})
        ..grant(
          const <StatModifier>[
            StatModifier.flat(Stat.attackPower, 20, source: sword),
            StatModifier.increased(Stat.attackPower, 0.5, source: sword),
            StatModifier.more(Stat.attackPower, 0.2, source: sword),
          ],
          sword,
        );

      expect(stats.value(Stat.attackPower), closeTo(216, 1e-9));

      expect(stats.removeBySource(sword), 3);
      expect(stats.value(Stat.attackPower), 100);
    });

    test('removing a source that granted nothing is not an error', () {
      final StatBlock stats = StatBlock(<Stat, double>{Stat.attackPower: 100});

      expect(stats.removeBySource(sword), 0);
      expect(stats.value(Stat.attackPower), 100);
    });

    test('grant rebinds authored modifiers to whoever granted them', () {
      // An item definition is authored once and worn by anyone.
      const List<StatModifier> plateArmour = <StatModifier>[
        StatModifier.flat(Stat.maxHealth, 50, source: ModifierSource.item('_')),
      ];

      final StatBlock stats = StatBlock(<Stat, double>{Stat.maxHealth: 200})
        ..grant(plateArmour, chest);

      expect(stats.value(Stat.maxHealth), 250);
      expect(stats.fromSource(chest), hasLength(1));
      expect(stats.removeBySource(chest), 1);
      expect(stats.value(Stat.maxHealth), 200);
    });

    test('a stat is clamped after the pipeline, not during it', () {
      // Stacked slows must not drive the beat to zero and let a unit act
      // infinitely often.
      final StatBlock stats =
          StatBlock(<Stat, double>{Stat.globalCooldown: 1})
            ..add(const StatModifier.increased(Stat.globalCooldown, -5,
                source: warCry));

      expect(stats.value(Stat.globalCooldown), Stat.globalCooldown.minimum);
    });

    test('setBase moves the authored value and keeps modifiers', () {
      final StatBlock stats = StatBlock(<Stat, double>{Stat.maxHealth: 200})
        ..add(const StatModifier.flat(Stat.maxHealth, 50, source: chest));

      expect(stats.value(Stat.maxHealth), 250);

      stats.setBase(Stat.maxHealth, 300);

      expect(stats.value(Stat.maxHealth), 350);
    });

    test('breakdown groups a stat by what is granting it', () {
      final StatBlock stats = StatBlock(<Stat, double>{Stat.maxHealth: 200})
        ..add(const StatModifier.flat(Stat.maxHealth, 50, source: chest))
        ..add(const StatModifier.flat(Stat.maxHealth, 10, source: warCry))
        ..add(const StatModifier.flat(Stat.attackPower, 10, source: sword));

      final Map<ModifierSource, List<StatModifier>> rows =
          stats.breakdown(Stat.maxHealth);

      expect(rows.keys, <ModifierSource>{chest, warCry});
      expect(rows[chest], hasLength(1));
    });
  });
}
