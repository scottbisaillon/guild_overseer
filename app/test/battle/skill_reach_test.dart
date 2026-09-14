import 'package:flutter_test/flutter_test.dart';
import 'package:guild_overseer/src/features/battle/data/mock_roster.dart';
import 'package:guild_overseer/src/features/battle/domain/party_formation.dart';
import 'package:guild_overseer/src/features/battle/domain/skill.dart';
import 'package:guild_overseer/src/features/battle/domain/skill_reach.dart';

/// What the party screen shows about a skill before a fight exists. It comes
/// out of the same resolver the fight uses, so these check the shapes the
/// player is promised are the shapes the rules produce.
void main() {
  const FormationSlot casterSlot = (row: 1, column: 0);

  Set<FormationSlot> column(int column) => <FormationSlot>{
        for (int row = 0; row < 3; row++) (row: row, column: column),
      };

  Set<FormationSlot> everywhere() => <FormationSlot>{
        for (int c = 0; c < 2; c++) ...column(c),
      };

  test('a single-target strike reaches one enemy cell', () {
    final SkillReach reach = reachOf(shieldSlam);

    expect(reach.enemies, <FormationSlot>{casterSlot});
    expect(reach.allies, isEmpty);
    expect(reach.coversSeveral, isFalse);
  });

  test('a rank skill reaches the whole rank the target stands in', () {
    final SkillReach reach = reachOf(cleave);

    expect(reach.enemies, column(0));
    expect(reach.coversSeveral, isTrue);
  });

  test('a row skill reaches the target and whoever stands behind it', () {
    final SkillReach reach = reachOf(volley);

    expect(reach.enemies, <FormationSlot>{
      (row: 1, column: 0),
      (row: 1, column: 1),
    });
  });

  test('a storm reaches every enemy cell and no friendly one', () {
    final SkillReach reach = reachOf(tempest);

    expect(reach.enemies, everywhere());
    expect(reach.allies, isEmpty);
  });

  test('a self buff reaches the caster and nobody else', () {
    final SkillReach reach = reachOf(fortify);

    expect(reach.allies, <FormationSlot>{casterSlot});
    expect(reach.enemies, isEmpty);
    expect(reach.caster, casterSlot);
  });

  test('a party heal reaches the whole party, caster included', () {
    final SkillReach reach = reachOf(rally);

    expect(reach.allies, everywhere());
    expect(reach.allies, contains(casterSlot));
    expect(reach.enemies, isEmpty);
  });

  test('a heal on one ally reaches one friendly cell', () {
    final SkillReach reach = reachOf(mend);

    expect(reach.allies.length, 1);
    expect(reach.enemies, isEmpty);
  });

  test('every skill in the pool reaches somebody', () {
    for (final SkillDefinition skill in kSkillPool) {
      expect(
        reachOf(skill).cellCount,
        greaterThan(0),
        reason: '${skill.name} previews as landing on nobody',
      );
    }
  });

  test('the skills that cover several cells are the ones that say so', () {
    for (final SkillDefinition skill in kSkillPool) {
      expect(
        reachOf(skill).coversSeveral,
        skill.presentation.area != null,
        reason: '${skill.name} reaches '
            '${reachOf(skill).cellCount} cells but '
            '${skill.presentation.area == null ? 'draws no' : 'draws an'} '
            'area footprint',
      );
    }
  });
}
