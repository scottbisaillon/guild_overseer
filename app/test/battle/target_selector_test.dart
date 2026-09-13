import 'package:flutter_test/flutter_test.dart';
import 'package:guild_overseer/src/core/domain/combat_role.dart';
import 'package:guild_overseer/src/core/domain/target_selector.dart';
import 'package:guild_overseer/src/features/battle/data/mock_roster.dart';
import 'package:guild_overseer/src/features/battle/domain/arena_layout.dart';
import 'package:guild_overseer/src/features/battle/domain/combatant.dart';
import 'package:guild_overseer/src/features/battle/domain/targeting.dart';

/// The selector table, run over the twelve-unit mockup board.
///
/// This is where off-by-one targeting bugs get caught, and it is also the
/// evidence for the whole composable-targeting idea: most of the selectors
/// below describe behaviour the game has never had, and not one of them
/// needed a line of resolver code to exist.
///
/// The board, for reading the expectations. Column 0 is the front line on both
/// sides; rows run top to bottom.
///
/// ```
///   allies                         enemies
///   col1      col0        |        col0      col1
///   Ysolde    Bramm       |        Warden    Acolyte      row 0
///   Fenn      Kessa       |        Ghoul A   Construct    row 1
///   Mira      Doren       |        Ghoul B   Hexweaver    row 2
/// ```
void main() {
  late List<Combatant> board;
  late Combatant bramm;
  late Combatant warden;

  Combatant byId(String id) => board.firstWhere((Combatant c) => c.id == id);

  setUp(() {
    board = buildMockRoster();
    bramm = byId('ally_bramm'); // tank, row 0, front line
    warden = byId('enemy_warden'); // tank, row 0, front line
  });

  List<String> select(
    TargetSelector selector, {
    Combatant? caster,
    Combatant? currentTarget,
  }) =>
      resolveTargets(
        selector: selector,
        caster: caster ?? bramm,
        currentTarget: currentTarget,
        units: board,
        layout: kArenaLayout,
      ).map((Combatant c) => c.id).toList();

  group('the shapes the game already uses', () {
    test('currentEnemy takes the locked target and nobody else', () {
      expect(
        select(TargetSelector.currentEnemy, currentTarget: warden),
        <String>['enemy_warden'],
      );
    });

    test('currentEnemyColumn takes the target rank in formation order', () {
      expect(
        select(TargetSelector.currentEnemyColumn, currentTarget: warden),
        <String>['enemy_warden', 'enemy_ghoul_a', 'enemy_ghoul_b'],
      );
    });

    test('mostWoundedAlly finds nobody while the side is whole', () {
      expect(select(TargetSelector.mostWoundedAlly), isEmpty);
    });

    test('mostWoundedAlly picks the worst off, and may pick the caster', () {
      byId('ally_fenn').applyDamage(100);
      expect(select(TargetSelector.mostWoundedAlly), <String>['ally_fenn']);

      bramm.applyDamage(400); // now far worse off than Fenn
      expect(select(TargetSelector.mostWoundedAlly), <String>['ally_bramm']);
    });

    test('a selector anchored on a dead target finds nobody', () {
      warden.applyDamage(9999);
      expect(select(TargetSelector.currentEnemy, currentTarget: warden), isEmpty);
      expect(
        select(TargetSelector.currentEnemyColumn, currentTarget: warden),
        isEmpty,
      );
    });
  });

  group('shapes that cost no new code', () {
    test('the whole opposing side', () {
      expect(
        select(const TargetSelector(
          side: TargetSide.enemies,
          count: TargetSelector.unlimited,
        )),
        hasLength(6),
      );
    });

    test('the three nearest enemies', () {
      expect(
        select(const TargetSelector(
          side: TargetSide.enemies,
          order: TargetOrder.nearest,
          count: 3,
        )),
        // The front rank, nearest first: they share Bramm's side of the arena.
        <String>['enemy_warden', 'enemy_ghoul_a', 'enemy_ghoul_b'],
      );
    });

    test('everyone in the caster own rank, across the line', () {
      expect(
        select(const TargetSelector(
          side: TargetSide.enemies,
          shape: TargetShape.sameRow,
          count: TargetSelector.unlimited,
        )),
        <String>['enemy_warden', 'enemy_acolyte'],
      );
    });

    test('execute: only enemies under a health threshold', () {
      final TargetSelector execute = const TargetSelector(
        side: TargetSide.enemies,
        order: TargetOrder.lowestHealthFraction,
        filters: <TargetFilter>[HealthBelowFilter(0.15)],
      );

      expect(select(execute), isEmpty, reason: 'nobody is hurt yet');

      byId('enemy_ghoul_a').applyDamage(250); // 15 of 265 left, under 15%
      byId('enemy_construct').applyDamage(100); // still well above

      expect(select(execute), <String>['enemy_ghoul_a']);
    });

    test('hunt the enemy healer, the Debuffer archetype', () {
      expect(
        select(const TargetSelector(
          side: TargetSide.enemies,
          order: TargetOrder.preferredRole,
          preferredRole: CombatRole.healer,
        )),
        <String>['enemy_acolyte'],
      );
    });

    test('a party-wide buff reaches the caster; an area attack does not', () {
      const TargetSelector partyWide = TargetSelector(
        side: TargetSide.allies,
        count: TargetSelector.unlimited,
        includeSelf: true,
      );
      const TargetSelector everyoneElse = TargetSelector(
        side: TargetSide.allies,
        count: TargetSelector.unlimited,
      );

      expect(select(partyWide), hasLength(6));
      expect(select(everyoneElse), hasLength(5));
      expect(select(everyoneElse), isNot(contains('ally_bramm')));
    });

    test('self, for a skill that only ever affects its caster', () {
      expect(select(TargetSelector.self), <String>['ally_bramm']);
    });
  });

  group('ranking', () {
    test('a cut keeps the best; no cut keeps formation order', () {
      // Six candidates, three wanted: ranked. Six wanted: untouched.
      const TargetSelector ranked = TargetSelector(
        side: TargetSide.enemies,
        order: TargetOrder.lowestHealthFraction,
        count: 3,
      );
      const TargetSelector everyone = TargetSelector(
        side: TargetSide.enemies,
        order: TargetOrder.lowestHealthFraction,
        count: TargetSelector.unlimited,
      );

      byId('enemy_hexweaver').applyDamage(200); // worst off by far

      expect(select(ranked).first, 'enemy_hexweaver');
      expect(
        select(everyone).first,
        'enemy_warden',
        reason: 'with nothing to cut, the pool keeps formation order',
      );
    });

    test('the dead are never candidates', () {
      byId('enemy_warden').applyDamage(9999);

      expect(
        select(const TargetSelector(
          side: TargetSide.enemies,
          count: TargetSelector.unlimited,
        )),
        isNot(contains('enemy_warden')),
      );
    });
  });

  group('selectTarget', () {
    test('a priority is just a named selector over the same resolver', () {
      // The Hexweaver hunts the party healer across the whole arena.
      final Combatant hexweaver = byId('enemy_hexweaver');

      expect(
        selectTarget(
          unit: hexweaver,
          candidates: board,
          layout: kArenaLayout,
        )?.id,
        'ally_ysolde',
      );
    });
  });
}
