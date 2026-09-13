import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:guild_overseer/src/core/domain/faction.dart';
import 'package:guild_overseer/src/core/domain/stat.dart';
import 'package:guild_overseer/src/core/domain/stat_modifier.dart';
import 'package:guild_overseer/src/core/events/game_event.dart';
import 'package:guild_overseer/src/core/domain/target_selector.dart';
import 'package:guild_overseer/src/features/battle/domain/arena_layout.dart';
import 'package:guild_overseer/src/features/battle/domain/combatant.dart';
import 'package:guild_overseer/src/features/battle/domain/effect_resolver.dart';
import 'package:guild_overseer/src/features/battle/domain/rotation.dart';
import 'package:guild_overseer/src/features/battle/domain/skill.dart';
import 'package:guild_overseer/src/core/domain/skill_effect.dart';

import 'battle_test_fixtures.dart';

/// One test per effect kind, resolved against a hand-built context.
///
/// These are the regression net for the resolver as the set of effects grows:
/// each one pins what a kind *means*, independently of any fight.
void main() {
  /// A random source that always rolls the middle of the range, so a magnitude
  /// is the authored one and the assertions can be exact.
  final math.Random noVariance = _FixedRandom(0.5);

  ResolutionContext contextFor(
    Combatant caster, {
    required List<GameEvent> log,
    math.Random? random,
    String label = 'Basic',
  }) =>
      ResolutionContext(
        caster: caster,
        label: label,
        random: random ?? noVariance,
        emit: log.add,
      );

  group('resolveEffect', () {
    test('damage scales off the caster, not the skill', () {
      final Combatant hero = unit(id: 'hero');
      final Combatant target = unit(id: 'target', faction: Faction.enemy);
      final List<GameEvent> log = <GameEvent>[];

      // Coefficient 3 against the default attack power of 10.
      resolveEffect(
        const DamageEffect(coefficient: 3),
        <Combatant>[target],
        contextFor(hero, log: log),
      );

      expect(target.health, 100 - 30);
      expect(log.whereType<DamageDealt>().single.amount, 30);
    });

    test('a sword makes every skill that scales off it hit harder', () {
      // The whole point of routing damage through the stat pipeline: the
      // effect was not edited, the caster was.
      final Combatant hero = unit(id: 'hero')
        ..stats.add(const StatModifier.flat(
          Stat.attackPower,
          5,
          source: ModifierSource.item('weapon'),
        ));
      final Combatant target = unit(id: 'target', faction: Faction.enemy);

      resolveEffect(
        const DamageEffect(coefficient: 3),
        <Combatant>[target],
        contextFor(hero, log: <GameEvent>[]),
      );

      expect(target.health, 100 - 45);
    });

    test('healing is capped at the target maximum and reports what landed', () {
      final Combatant healer = unit(id: 'healer');
      final Combatant friend = unit(id: 'friend')..applyDamage(10);
      final List<GameEvent> log = <GameEvent>[];

      resolveEffect(
        const HealEffect(coefficient: 5),
        <Combatant>[friend],
        contextFor(healer, log: log),
      );

      expect(friend.health, 100);
      // 50 was rolled; only the 10 that fit is reported.
      expect(log.whereType<HealApplied>().single.amount, 10);
    });

    test('a killing blow reports the death once', () {
      final Combatant hero = unit(id: 'hero');
      final Combatant target = unit(id: 'target', faction: Faction.enemy)
        ..applyDamage(90);
      final List<GameEvent> log = <GameEvent>[];

      resolveEffect(
        const DamageEffect(coefficient: 3),
        <Combatant>[target],
        contextFor(hero, log: log),
      );

      expect(target.isAlive, isFalse);
      expect(log.whereType<UnitDied>(), hasLength(1));
    });

    test('an effect rolls once per target, so an area skill spreads', () {
      final Combatant hero = unit(id: 'hero');
      final List<Combatant> targets = <Combatant>[
        unit(id: 'a', faction: Faction.enemy),
        unit(id: 'b', faction: Faction.enemy),
        unit(id: 'c', faction: Faction.enemy),
      ];
      final _CountingRandom counter = _CountingRandom();

      resolveEffect(
        const DamageEffect(coefficient: 3),
        targets,
        contextFor(hero, log: <GameEvent>[], random: counter),
      );

      expect(counter.draws, 3);
    });

    test('variance is per effect and bounds the roll', () {
      final Combatant hero = unit(id: 'hero');
      final Combatant low = unit(id: 'low', faction: Faction.enemy);
      final Combatant high = unit(id: 'high', faction: Faction.enemy);

      resolveEffect(
        const DamageEffect(coefficient: 3, variance: 0.15),
        <Combatant>[low],
        contextFor(hero, log: <GameEvent>[], random: _FixedRandom(0)),
      );
      resolveEffect(
        const DamageEffect(coefficient: 3, variance: 0.15),
        <Combatant>[high],
        contextFor(hero, log: <GameEvent>[], random: _FixedRandom(1)),
      );

      // 30 either side of +/-15%, rounded.
      expect(100 - low.health, 26); // 25.5 rounds to 26
      expect(100 - high.health, 35); // 34.5 rounds to 35
    });

    test('an effect with no targets does nothing at all', () {
      final Combatant hero = unit(id: 'hero');
      final List<GameEvent> log = <GameEvent>[];

      resolveEffect(
        const DamageEffect(coefficient: 3),
        const <Combatant>[],
        contextFor(hero, log: log),
      );

      expect(log, isEmpty);
    });
  });

  group('multi-effect skills', () {
    /// The capability the effect list exists for: one skill, two effects, each
    /// landing on somebody different.
    const SkillDefinition recklessStrike = SkillDefinition(
      id: 'reckless',
      name: 'Reckless Strike',
      cooldown: 2,
      effects: <EffectSpec>[
        EffectSpec(
          selector: TargetSelector.currentEnemy,
          effect: DamageEffect(coefficient: 6),
        ),
        // The recoil: the caster is the most wounded ally the moment it lands.
        EffectSpec(
          selector: TargetSelector.mostWoundedAlly,
          effect: DamageEffect(coefficient: 1),
        ),
      ],
    );

    test('each effect resolves against its own targeting', () {
      final Combatant hero =
          unit(id: 'hero', skills: const <SkillDefinition>[recklessStrike]);
      final Combatant villain = unit(id: 'villain', faction: Faction.enemy);
      // Somebody on the caster's side has to be wounded for the recoil to
      // have a target.
      final Combatant friend = unit(id: 'friend', row: 1)..applyDamage(20);
      final List<Combatant> units = <Combatant>[hero, friend, villain];

      final RotationDecision decision = selectSkill(
        unit: hero,
        currentTarget: villain,
        units: units,
        layout: kArenaLayout,
      )!;

      expect(decision.effects, hasLength(2));
      expect(decision.effects.first.targets.single.id, 'villain');
      expect(decision.effects.last.targets.single.id, 'friend');
      expect(
        decision.targets.map((Combatant c) => c.id),
        <String>['villain', 'friend'],
      );
    });

    test('a skill still fires when only some of its effects have targets', () {
      // Nobody is wounded, so the recoil has nowhere to land — the strike
      // itself must not be held up by that.
      final Combatant hero =
          unit(id: 'hero', skills: const <SkillDefinition>[recklessStrike]);
      final Combatant villain = unit(id: 'villain', faction: Faction.enemy);

      final RotationDecision decision = selectSkill(
        unit: hero,
        currentTarget: villain,
        units: <Combatant>[hero, villain],
        layout: kArenaLayout,
      )!;

      expect(decision.effects, hasLength(1));
      expect(decision.effects.single.targets.single.id, 'villain');
    });

    test('a unit touched by two effects is listed once for the renderer', () {
      const SkillDefinition doubleHit = SkillDefinition(
        id: 'double',
        name: 'Double',
          cooldown: 1,
        effects: <EffectSpec>[
          EffectSpec(
            selector: TargetSelector.currentEnemy,
            effect: DamageEffect(coefficient: 1),
          ),
          EffectSpec(
            selector: TargetSelector.currentEnemy,
            effect: DamageEffect(coefficient: 1),
          ),
        ],
      );
      final Combatant hero =
          unit(id: 'hero', skills: const <SkillDefinition>[doubleHit]);
      final Combatant villain = unit(id: 'villain', faction: Faction.enemy);

      final RotationDecision decision = selectSkill(
        unit: hero,
        currentTarget: villain,
        units: <Combatant>[hero, villain],
        layout: kArenaLayout,
      )!;

      expect(decision.effects, hasLength(2));
      expect(decision.targets, hasLength(1));
    });

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

/// Counts how many times the resolver reached for the random source.
class _CountingRandom implements math.Random {
  int draws = 0;

  @override
  double nextDouble() {
    draws++;
    return 0.5;
  }

  @override
  bool nextBool() => throw UnimplementedError();

  @override
  int nextInt(int max) => throw UnimplementedError();
}
