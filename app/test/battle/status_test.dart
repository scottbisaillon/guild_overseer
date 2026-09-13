import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:guild_overseer/src/core/domain/faction.dart';
import 'package:guild_overseer/src/core/domain/skill_effect.dart';
import 'package:guild_overseer/src/core/domain/stat.dart';
import 'package:guild_overseer/src/core/domain/stat_modifier.dart';
import 'package:guild_overseer/src/core/domain/status.dart';
import 'package:guild_overseer/src/core/events/game_event.dart';
import 'package:guild_overseer/src/features/battle/domain/combatant.dart';
import 'package:guild_overseer/src/features/battle/domain/effect_resolver.dart';

import 'battle_test_fixtures.dart';

/// Statuses: buffs, debuffs and damage over time, which are one shape.
void main() {
  const StatusDefinition bleed = StatusDefinition(
    id: 'bleed',
    name: 'Bleed',
    duration: 6,
    tickInterval: 2,
    tags: <StatusTag>{StatusTag.debuff, StatusTag.bleed},
    maxStacks: 3,
    policy: StackPolicy.stack,
    onTick: <SkillEffect>[DamageEffect(coefficient: 1)],
  );

  const StatusDefinition braced = StatusDefinition(
    id: 'braced',
    name: 'Braced',
    duration: 4,
    tags: <StatusTag>{StatusTag.buff},
    modifiers: <StatModifier>[
      StatModifier.increased(
        Stat.damageTakenMultiplier,
        -0.5,
        source: ModifierSource.status('braced'),
      ),
    ],
  );

  const StatusDefinition hardy = StatusDefinition(
    id: 'hardy',
    name: 'Hardy',
    duration: 4,
    tags: <StatusTag>{StatusTag.buff},
    modifiers: <StatModifier>[
      StatModifier.flat(
        Stat.maxHealth,
        100,
        source: ModifierSource.status('hardy'),
      ),
    ],
  );

  ResolutionContext contextFor(Combatant caster, List<GameEvent> log) =>
      ResolutionContext(
        caster: caster,
        label: 'Test',
        random: _FixedRandom(0.5),
        emit: log.add,
      );

  void apply(
    StatusDefinition definition,
    Combatant target, {
    Combatant? source,
    List<GameEvent>? log,
    int stacks = 1,
  }) {
    final Combatant caster = source ?? target;
    resolveEffect(
      ApplyStatusEffect(definition, stacks: stacks),
      <Combatant>[target],
      contextFor(caster, log ?? <GameEvent>[]),
    );
  }

  /// Advances a unit's statuses the way the simulation does.
  List<GameEvent> run(Combatant unit, double seconds, {Combatant? source}) {
    final List<GameEvent> log = <GameEvent>[];
    const double step = 1 / 60;
    for (double t = 0; t < seconds; t += step) {
      unit.statuses.advance(
        step,
        onTick: (ActiveStatus status) {
          final ResolutionContext context = ResolutionContext(
            caster: source ?? unit,
            label: status.definition.name,
            random: _FixedRandom(0.5),
            emit: log.add,
            statSnapshot: status.statSnapshot,
          );
          for (final SkillEffect effect in status.definition.onTick) {
            for (int i = 0; i < status.stacks; i++) {
              resolveEffect(effect, <Combatant>[unit], context);
            }
          }
        },
        onExpire: (ActiveStatus status) => log.add(StatusEnded(
          unitId: unit.id,
          unitName: unit.name,
          statusId: status.id,
          statusName: status.definition.name,
          expired: true,
        )),
      );
    }
    return log;
  }

  group('buffs reach the unit through the stat pipeline', () {
    test('a buff applies its modifiers and expiry takes them back', () {
      final Combatant hero = unit(id: 'hero');
      expect(hero.stats.value(Stat.damageTakenMultiplier), 1);

      apply(braced, hero);
      expect(hero.stats.value(Stat.damageTakenMultiplier), 0.5);

      run(hero, 5);
      expect(hero.stats.value(Stat.damageTakenMultiplier), 1);
      expect(hero.statuses.has('braced'), isFalse);
    });

    test('mitigation applies however the damage arrived', () {
      final Combatant plain = unit(id: 'plain', faction: Faction.enemy);
      final Combatant braced_ = unit(id: 'braced', faction: Faction.enemy);
      apply(braced, braced_);

      final Combatant attacker = unit(id: 'attacker');
      resolveEffect(const DamageEffect(coefficient: 4), <Combatant>[plain],
          contextFor(attacker, <GameEvent>[]));
      resolveEffect(const DamageEffect(coefficient: 4), <Combatant>[braced_],
          contextFor(attacker, <GameEvent>[]));

      expect(100 - plain.health, 40);
      expect(100 - braced_.health, 20);
    });

    test('a buff that grants health does not heal, and losing it does not '
        'kill', () {
      final Combatant hero = unit(id: 'hero', maxHealth: 200);
      hero.applyDamage(100);

      apply(hardy, hero);
      expect(hero.maxHealth, 300);
      expect(hero.health, 150, reason: 'half of 300, not 100 of 300');

      run(hero, 5);
      expect(hero.maxHealth, 200);
      expect(hero.health, 100);
      expect(hero.isAlive, isTrue);
    });
  });

  group('damage over time', () {
    test('ticks on its interval and stops when it runs out', () {
      final Combatant victim = unit(id: 'victim');
      apply(bleed, victim);

      final List<GameEvent> log = run(victim, 10);

      // 6s at 2s intervals: three ticks, then it ends.
      expect(log.whereType<DamageDealt>(), hasLength(3));
      expect(100 - victim.health, 30);
      expect(log.whereType<StatusEnded>(), hasLength(1));
      expect(victim.statuses.has('bleed'), isFalse);
    });

    test('a tick is ordinary damage: it reports, and it can kill', () {
      final Combatant victim = unit(id: 'victim')..applyDamage(95);
      apply(bleed, victim);

      final List<GameEvent> log = run(victim, 3);

      expect(victim.isAlive, isFalse);
      expect(log.whereType<UnitDied>(), hasLength(1));
      expect(log.whereType<DamageDealt>().single.skillName, 'Bleed');
    });

    test('a tick is as strong as its author was, even once they are dead', () {
      final Combatant author = unit(id: 'author')
        ..stats.add(const StatModifier.flat(
          Stat.attackPower,
          10,
          source: ModifierSource.item('weapon'),
        ));
      final Combatant victim = unit(id: 'victim', faction: Faction.enemy);

      // Applied while the author holds a sword worth double attack power.
      apply(bleed, victim, source: author);

      // The author then dies and the sword goes with them.
      author.stats.removeBySource(const ModifierSource.item('weapon'));
      author.applyDamage(999);

      run(victim, 3, source: author);

      // 20 attack power at application, not the 10 the corpse has now.
      expect(100 - victim.health, 20);
    });
  });

  group('stacking', () {
    test('stacks bite once each and refresh the duration', () {
      final Combatant victim = unit(id: 'victim', maxHealth: 500);
      apply(bleed, victim);
      apply(bleed, victim);

      expect(victim.statuses.stacksOf('bleed'), 2);

      final List<GameEvent> log = run(victim, 3);
      // One tick at 2s, two stacks' worth.
      expect(log.whereType<DamageDealt>(), hasLength(2));
      expect(500 - victim.health, 20);
    });

    test('stacks are capped', () {
      final Combatant victim = unit(id: 'victim');
      for (int i = 0; i < 10; i++) {
        apply(bleed, victim);
      }
      expect(victim.statuses.stacksOf('bleed'), 3);
    });

    test('a refreshing status resets its clock without stacking', () {
      final Combatant hero = unit(id: 'hero');
      apply(braced, hero);
      run(hero, 3);
      expect(hero.statuses.has('braced'), isTrue);

      apply(braced, hero); // refreshed at 1s remaining
      run(hero, 3);

      expect(hero.statuses.has('braced'), isTrue,
          reason: 'the refresh bought another 4 seconds');
      expect(hero.statuses.stacksOf('braced'), 1);
    });

    test('every stack grants the modifiers again', () {
      const StatusDefinition stackingBuff = StatusDefinition(
        id: 'resolve',
        name: 'Resolve',
        duration: 10,
        maxStacks: 3,
        policy: StackPolicy.stack,
        modifiers: <StatModifier>[
          StatModifier.flat(
            Stat.attackPower,
            5,
            source: ModifierSource.status('resolve'),
          ),
        ],
      );
      final Combatant hero = unit(id: 'hero');

      apply(stackingBuff, hero);
      expect(hero.stats.value(Stat.attackPower), 15);

      apply(stackingBuff, hero);
      expect(hero.stats.value(Stat.attackPower), 20);

      hero.statuses.remove('resolve');
      expect(hero.stats.value(Stat.attackPower), 10);
    });
  });

  group('cleansing names a kind, not a list', () {
    test('a cleanse strips a debuff and leaves the buff alone', () {
      final Combatant hero = unit(id: 'hero');
      apply(bleed, hero);
      apply(braced, hero);

      final List<GameEvent> log = <GameEvent>[];
      resolveEffect(
        const RemoveStatusEffect(tags: <StatusTag>{StatusTag.debuff}),
        <Combatant>[hero],
        contextFor(hero, log),
      );

      expect(hero.statuses.has('bleed'), isFalse);
      expect(hero.statuses.has('braced'), isTrue);
      expect(log.whereType<StatusEnded>().single.expired, isFalse);
    });

    test('a cleanse covers debuffs written after it', () {
      // The point of tags: this status did not exist when the cleanse did.
      const StatusDefinition newCurse = StatusDefinition(
        id: 'curse_of_something',
        name: 'Curse',
        duration: 5,
        tags: <StatusTag>{StatusTag.debuff},
      );
      final Combatant hero = unit(id: 'hero');
      apply(newCurse, hero);

      resolveEffect(
        const RemoveStatusEffect(tags: <StatusTag>{StatusTag.debuff}),
        <Combatant>[hero],
        contextFor(hero, <GameEvent>[]),
      );

      expect(hero.statuses.isEmpty, isTrue);
    });

    test('cleansing nothing is a normal outcome', () {
      final Combatant hero = unit(id: 'hero');
      final List<GameEvent> log = <GameEvent>[];

      resolveEffect(
        const RemoveStatusEffect(tags: <StatusTag>{StatusTag.debuff}),
        <Combatant>[hero],
        contextFor(hero, log),
      );

      expect(log, isEmpty);
    });

    test('a cleanse takes only as many as it was asked for', () {
      final Combatant hero = unit(id: 'hero');
      apply(bleed, hero);
      apply(
        const StatusDefinition(
          id: 'slow',
          name: 'Slow',
          duration: 5,
          tags: <StatusTag>{StatusTag.debuff},
        ),
        hero,
      );

      resolveEffect(
        const RemoveStatusEffect(tags: <StatusTag>{StatusTag.debuff}),
        <Combatant>[hero],
        contextFor(hero, <GameEvent>[]),
      );

      expect(hero.statuses.active, hasLength(1));
    });
  });

  test('the dead carry nothing', () {
    final Combatant corpse = unit(id: 'corpse')..applyDamage(999);
    apply(bleed, corpse);

    expect(corpse.statuses.isEmpty, isTrue);
  });
}

/// Always returns the same roll, so magnitudes are exact.
class _FixedRandom implements math.Random {
  _FixedRandom(this.roll);

  final double roll;

  @override
  double nextDouble() => roll;

  @override
  bool nextBool() => throw UnimplementedError();

  @override
  int nextInt(int max) => throw UnimplementedError();
}
