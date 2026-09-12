import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:guild_overseer/src/core/domain/combat_snapshot.dart';
import 'package:guild_overseer/src/core/domain/faction.dart';
import 'package:guild_overseer/src/core/events/game_event.dart';
import 'package:guild_overseer/src/features/battle/data/mock_roster.dart';
import 'package:guild_overseer/src/features/battle/domain/battle_simulation.dart';
import 'package:guild_overseer/src/features/battle/domain/combatant.dart';

import 'battle_test_fixtures.dart';

/// Runs the fight at a fixed step until it resolves, or [limit] seconds pass.
void runToCompletion(BattleSimulation sim, {double limit = 120}) {
  const double dt = 1 / 60;
  while (sim.status == BattleStatus.running && sim.elapsed < limit) {
    sim.update(dt);
  }
}

void main() {
  group('BattleSimulation', () {
    test('does nothing until it is started', () {
      final BattleSimulation sim =
          BattleSimulation(rosterBuilder: buildMockRoster);
      addTearDown(sim.dispose);

      sim.update(1);

      expect(sim.status, BattleStatus.notStarted);
      expect(sim.elapsed, 0);
    });

    test('the mock roster resolves to a winner', () {
      final BattleSimulation sim =
          BattleSimulation(rosterBuilder: buildMockRoster);
      addTearDown(sim.dispose);

      sim.start();
      runToCompletion(sim);

      expect(sim.status, BattleStatus.finished);
      expect(sim.winner, isNotNull);
      final Faction loser = sim.winner!.opposing;
      expect(
        sim.units.where((Combatant c) => c.faction == loser && c.isAlive),
        isEmpty,
      );
    });

    test('the same seed replays the same fight', () {
      BattleSimulation build() =>
          BattleSimulation(rosterBuilder: buildMockRoster, seed: 99);

      final BattleSimulation first = build()..start();
      final BattleSimulation second = build()..start();
      addTearDown(first.dispose);
      addTearDown(second.dispose);

      runToCompletion(first);
      runToCompletion(second);

      expect(second.winner, first.winner);
      expect(second.elapsed, closeTo(first.elapsed, 0.0001));
      expect(
        second.units.map((Combatant c) => c.health),
        first.units.map((Combatant c) => c.health),
      );
    });

    test('restart rewinds to the opening state', () {
      final BattleSimulation sim =
          BattleSimulation(rosterBuilder: buildMockRoster);
      addTearDown(sim.dispose);

      sim.start();
      runToCompletion(sim);
      final double resolvedAt = sim.elapsed;

      sim.restart();

      expect(sim.status, BattleStatus.running);
      expect(sim.elapsed, 0);
      expect(sim.winner, isNull);
      expect(
        sim.units.every((Combatant c) => c.health == c.maxHealth),
        isTrue,
      );

      runToCompletion(sim);
      expect(sim.elapsed, closeTo(resolvedAt, 0.0001));
    });

    test('a paused fight does not advance', () {
      final BattleSimulation sim =
          BattleSimulation(rosterBuilder: buildMockRoster);
      addTearDown(sim.dispose);

      sim.start();
      for (int i = 0; i < 60; i++) {
        sim.update(1 / 60);
      }
      sim.pause();
      final double pausedAt = sim.elapsed;

      for (int i = 0; i < 60; i++) {
        sim.update(1 / 60);
      }

      expect(sim.elapsed, pausedAt);

      sim.resume();
      sim.update(1 / 60);

      expect(sim.elapsed, greaterThan(pausedAt));
    });

    test('publishes the lifecycle and the killing blow', () async {
      final BattleSimulation sim =
          BattleSimulation(rosterBuilder: buildMockRoster);
      addTearDown(sim.dispose);

      final List<GameEvent> events = <GameEvent>[];
      final StreamSubscription<GameEvent> subscription =
          sim.events.listen(events.add);
      addTearDown(subscription.cancel);

      sim.start();
      runToCompletion(sim);
      await Future<void>.delayed(Duration.zero);

      expect(events.whereType<BattleStarted>(), hasLength(1));
      expect(events.whereType<BattleEnded>(), hasLength(1));
      expect(events.whereType<DamageDealt>(), isNotEmpty);
      expect(
        events.whereType<UnitDied>().length,
        sim.units.where((Combatant c) => !c.isAlive).length,
      );
      expect(events.last, isA<BattleEnded>());
    });

    test('a wiped side stops fighting back', () {
      // One ally against one enemy with a fraction of the health: the enemy
      // must die and the fight must end rather than trading forever.
      final BattleSimulation sim = BattleSimulation(
        rosterBuilder: () => <Combatant>[
          unit(id: 'hero', maxHealth: 100),
          unit(id: 'villain', faction: Faction.enemy, maxHealth: 20),
        ],
      );
      addTearDown(sim.dispose);

      sim.start();
      runToCompletion(sim, limit: 30);

      expect(sim.winner, Faction.ally);
      expect(sim.unitById('villain')!.isAlive, isFalse);
      // Both sides act on the same beat, so the villain lands hits before it
      // drops — but nothing after.
      final double survivorHealth = sim.unitById('hero')!.health;
      expect(survivorHealth, lessThan(100));
      expect(survivorHealth, greaterThan(0));
    });
  });
}
