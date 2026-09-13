import 'package:flutter_test/flutter_test.dart';
import 'package:guild_overseer/src/core/domain/stat.dart';
import 'package:guild_overseer/src/core/domain/stat_modifier.dart';
import 'package:guild_overseer/src/features/battle/domain/combatant.dart';

import 'battle_test_fixtures.dart';

/// A unit reads its numbers through the modifier pipeline, so a buff and a
/// breastplate reach it the same way. These are the end-to-end checks that the
/// seam actually works from a unit's point of view.
void main() {
  const ModifierSource chest = ModifierSource.item('chest');
  const ModifierSource fortify = ModifierSource.status('fortify');

  group('Combatant stats', () {
    test('a unit starts at the health it was authored with', () {
      final Combatant hero = unit(id: 'hero', maxHealth: 200);

      expect(hero.maxHealth, 200);
      expect(hero.health, 200);
      expect(hero.stats.base(Stat.maxHealth), 200);
    });

    test('equipping raises max health and keeps the unit at full', () {
      final Combatant hero = unit(id: 'hero', maxHealth: 200)
        ..stats.add(
          const StatModifier.flat(Stat.maxHealth, 50, source: chest),
        )
        ..refreshStats();

      expect(hero.maxHealth, 250);
      expect(hero.health, 250);
    });

    test('a wounded unit keeps its health fraction across a gear change', () {
      final Combatant hero = unit(id: 'hero', maxHealth: 200);
      hero.applyDamage(100);
      expect(hero.healthFraction, 0.5);

      hero.stats.add(const StatModifier.flat(Stat.maxHealth, 200, source: chest));
      hero.refreshStats();

      // Half of 400, not 100 out of 400: a breastplate is not a heal.
      expect(hero.maxHealth, 400);
      expect(hero.health, 200);
      expect(hero.healthFraction, 0.5);
    });

    test('losing a buff scales health down rather than killing', () {
      final Combatant hero = unit(id: 'hero', maxHealth: 200)
        ..stats.add(
          const StatModifier.flat(Stat.maxHealth, 200, source: fortify),
        )
        ..refreshStats();
      hero.applyDamage(200);
      expect(hero.health, 200);

      hero.stats.removeBySource(fortify);
      hero.refreshStats();

      expect(hero.maxHealth, 200);
      expect(hero.health, 100);
      expect(hero.isAlive, isTrue);
    });

    test('the dead stay dead through a stat change', () {
      final Combatant hero = unit(id: 'hero', maxHealth: 200);
      hero.applyDamage(200);
      expect(hero.isAlive, isFalse);

      hero.stats.add(const StatModifier.flat(Stat.maxHealth, 500, source: chest));
      hero.refreshStats();

      expect(hero.health, 0);
      expect(hero.isAlive, isFalse);
    });

    test('refreshStats is idempotent', () {
      final Combatant hero = unit(id: 'hero', maxHealth: 200);
      hero.applyDamage(100);

      hero.stats.add(const StatModifier.flat(Stat.maxHealth, 200, source: chest));
      hero.refreshStats();
      hero.refreshStats();
      hero.refreshStats();

      expect(hero.health, 200);
      expect(hero.maxHealth, 400);
    });

    test('the global cooldown comes through the pipeline too', () {
      final Combatant hero = unit(id: 'hero', globalCooldown: 1);
      expect(hero.globalCooldown, 1);

      hero.stats.add(
        const StatModifier.increased(Stat.globalCooldown, -0.2, source: fortify),
      );

      expect(hero.globalCooldown, closeTo(0.8, 1e-9));
    });
  });
}
