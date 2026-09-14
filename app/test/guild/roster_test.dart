import 'package:flutter_test/flutter_test.dart';
import 'package:guild_overseer/src/core/domain/combat_role.dart';
import 'package:guild_overseer/src/features/guild/domain/member.dart';
import 'package:guild_overseer/src/features/guild/domain/roster.dart';

void main() {
  Member member(
    String id, {
    CombatRole role = CombatRole.meleeDps,
    bool isPlayerCharacter = false,
    MemberAvailability availability = MemberAvailability.ready,
  }) =>
      Member(
        id: id,
        name: id,
        role: role,
        isPlayerCharacter: isPlayerCharacter,
        availability: availability,
      );

  final Roster guild = Roster(<Member>[
    member('you', role: CombatRole.tank, isPlayerCharacter: true),
    member('bryn', role: CombatRole.healer),
    member('sel', availability: MemberAvailability.onRun),
  ]);

  group('Roster', () {
    test('lists members in the order they joined', () {
      expect(guild.ids, <String>['you', 'bryn', 'sel']);
    });

    test('finds a member by id, and says so when there is none', () {
      expect(guild.require('bryn').name, 'bryn');
      expect(guild.maybe('nobody'), isNull);
      expect(() => guild.require('nobody'), throwsArgumentError);
    });

    test('only the members who are free read as ready', () {
      expect(guild.ready.map((Member m) => m.id), <String>['you', 'bryn']);
    });

    test('finds the player character among everyone else', () {
      expect(guild.playerCharacter?.id, 'you');
      expect(const Roster.empty().playerCharacter, isNull);
    });

    test('filters by role', () {
      expect(guild.withRole(CombatRole.healer).map((Member m) => m.id),
          <String>['bryn']);
    });

    test('adding a member with a known id replaces them in place', () {
      final Roster after =
          guild.withMember(guild.require('bryn').adjustMorale(-20));

      expect(after.size, guild.size);
      expect(after.ids, guild.ids);
      expect(after.require('bryn').morale.value, 30);
    });

    test('updating by id leaves everyone else alone', () {
      final Roster after = guild.updated('sel', (Member m) => m.gainExperience(500));

      expect(after.require('sel').experience, 500);
      expect(after.require('bryn'), guild.require('bryn'));
    });

    test('updating somebody who left is not a crash', () {
      expect(guild.updated('ghost', (Member m) => m.adjustMorale(-10)), guild);
    });

    test('a whole party can be updated at once', () {
      final Roster after = guild.updatedAll(
        <String>['bryn', 'sel'],
        (Member m) => m.adjustFatigue(20),
      );

      expect(after.require('bryn').fatigue.value, 20);
      expect(after.require('sel').fatigue.value, 20);
      expect(after.require('you').fatigue.value, 0);
    });

    test('dismissing removes exactly one member', () {
      final Roster after = guild.without('bryn');

      expect(after.ids, <String>['you', 'sel']);
      expect(guild.ids, <String>['you', 'bryn', 'sel'], reason: 'immutable');
    });

    test('dismissing somebody who already left does nothing', () {
      expect(guild.without('ghost'), guild);
    });

    // The rule from the design doc, enforced where it cannot be routed around.
    test('the player character cannot be dismissed', () {
      expect(() => guild.without('you'), throwsStateError);
    });

    test('round-trips through json', () {
      expect(Roster.fromJson(guild.toJson()), guild);
    });
  });
}
