import 'package:flutter_test/flutter_test.dart';
import 'package:guild_overseer/src/core/domain/combat_role.dart';
import 'package:guild_overseer/src/core/domain/item.dart';
import 'package:guild_overseer/src/core/domain/meter.dart';
import 'package:guild_overseer/src/core/domain/stat.dart';
import 'package:guild_overseer/src/core/domain/target_priority.dart';
import 'package:guild_overseer/src/features/guild/domain/experience_curve.dart';
import 'package:guild_overseer/src/features/guild/domain/member.dart';

void main() {
  Member recruit() => Member.recruit(
        id: 'bryn',
        name: 'Bryn',
        role: CombatRole.tank,
        level: 4,
        priority: TargetPriority.frontline,
        baseStats: <Stat, double>{Stat.maxHealth: 260},
        skillIds: <String>['shield_slam', 'strike'],
        traitIds: <String>['veteran'],
      );

  group('Member', () {
    test('a recruit arrives at the level they were rolled at', () {
      expect(recruit().level, 4);
      expect(recruit().experience, ExperienceCurve.totalFor(4));
    });

    test('level is read off experience, so the two cannot disagree', () {
      final Member trained =
          recruit().gainExperience(ExperienceCurve.remainingToNextLevel(
        recruit().experience,
      ));

      expect(trained.level, 5);
    });

    test('experience earned below the threshold does not level anyone', () {
      final Member trained = recruit().gainExperience(1);

      expect(trained.level, 4);
      expect(trained.levelProgress, greaterThan(0));
    });

    test('condition changes clamp at the ends of the meter', () {
      expect(recruit().adjustMorale(500).morale, Meter.full);
      expect(recruit().adjustFatigue(-10).fatigue, Meter.empty);
    });

    test('equipping a slot replaces what was in it', () {
      final Member armed = recruit()
          .equip(GearSlot.weapon, 'iron_greatsword')
          .equip(GearSlot.weapon, 'wardens_shield');

      expect(armed.gearIn(GearSlot.weapon), 'wardens_shield');
      expect(armed.gear.length, 1);
    });

    test('unequipping an empty slot is not an error', () {
      expect(recruit().unequip(GearSlot.helm).gear, isEmpty);
    });

    test('an edit leaves the original alone', () {
      final Member original = recruit();
      original.adjustMorale(-40).equip(GearSlot.helm, 'cap');

      expect(original.morale, Meter.half);
      expect(original.gear, isEmpty);
    });

    test('the player character flag survives every edit', () {
      final Member player = Member.recruit(
        id: 'you',
        name: 'You',
        role: CombatRole.healer,
        isPlayerCharacter: true,
      );

      expect(player.adjustLoyalty(-100).isPlayerCharacter, isTrue);
    });

    test('round-trips through json', () {
      final Member saved = recruit()
          .equip(GearSlot.weapon, 'wardens_shield')
          .adjustFatigue(35)
          .withAvailability(MemberAvailability.resting);

      expect(Member.fromJson(saved.toJson()), saved);
    });

    // A member is player progress. Losing the roster because an enum value was
    // renamed between versions is not a trade worth making.
    test('a save naming something unknown falls back rather than throwing', () {
      final Map<String, Object?> json = recruit().toJson()
        ..['role'] = 'shapeshifter'
        ..['availability'] = 'carousing'
        ..['baseStats'] = <String, Object?>{'luck': 12, 'maxHealth': 260};

      final Member loaded = Member.fromJson(json);

      expect(loaded.role, CombatRole.meleeDps);
      expect(loaded.availability, MemberAvailability.ready);
      expect(loaded.baseStats, <Stat, double>{Stat.maxHealth: 260});
    });
  });
}
