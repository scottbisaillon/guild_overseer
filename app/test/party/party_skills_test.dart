import 'package:flutter_test/flutter_test.dart';
import 'package:guild_overseer/src/features/battle/domain/party_skills.dart';

/// The rules of a rotation live in this type, so the screen can hand it any
/// list a player managed to build and get back one a unit could fight with.
void main() {
  group('choosing', () {
    test('a unit takes the skills it is given, in the order given', () {
      final PartySkills skills = const PartySkills.empty()
          .withUnit('ally_bramm', <String>['fortify', 'cleave']);

      expect(skills.forUnit('ally_bramm'), <String>['fortify', 'cleave']);
    });

    test('a unit nobody chose for has no entry, not an empty one', () {
      const PartySkills skills = PartySkills.empty();

      expect(skills.forUnit('ally_bramm'), isNull);
      expect(skills.hasChoiceFor('ally_bramm'), isFalse);
    });

    test('choosing nothing is a choice, and not the same as choosing', () {
      final PartySkills skills =
          const PartySkills.empty().withUnit('ally_bramm', <String>[]);

      expect(skills.hasChoiceFor('ally_bramm'), isTrue);
      expect(skills.forUnit('ally_bramm'), isEmpty);
    });

    test('a rotation is cut to the slots a unit has', () {
      final PartySkills skills = const PartySkills.empty().withUnit(
        'ally_bramm',
        <String>['fortify', 'cleave', 'mend', 'rally', 'disrupt'],
      );

      expect(skills.forUnit('ally_bramm')?.length, kChosenSkillSlots);
      expect(skills.forUnit('ally_bramm')?.first, 'fortify');
    });

    test('the same skill twice is the same skill once', () {
      final PartySkills skills = const PartySkills.empty()
          .withUnit('ally_bramm', <String>['cleave', 'cleave', 'mend']);

      expect(skills.forUnit('ally_bramm'), <String>['cleave', 'mend']);
    });

    test('resetting a unit hands it back to what it was authored with', () {
      final PartySkills skills = const PartySkills.empty()
          .withUnit('ally_bramm', <String>['cleave'])
          .withUnit('ally_fenn', <String>['mend'])
          .clearUnit('ally_bramm');

      expect(skills.hasChoiceFor('ally_bramm'), isFalse);
      expect(skills.forUnit('ally_fenn'), <String>['mend']);
    });

    test('only the units that are going keep their choices', () {
      final PartySkills skills = const PartySkills.empty()
          .withUnit('ally_bramm', <String>['cleave'])
          .withUnit('ally_fenn', <String>['mend'])
          .retaining(<String>['ally_fenn']);

      expect(skills.hasChoiceFor('ally_bramm'), isFalse);
      expect(skills.forUnit('ally_fenn'), <String>['mend']);
    });
  });

  group('travelling in a link', () {
    test('what is encoded is what comes back', () {
      final PartySkills skills = const PartySkills.empty()
          .withUnit('ally_bramm', <String>['fortify', 'shield_slam'])
          .withUnit('ally_fenn', <String>['piercing_shot']);

      expect(PartySkills.decode(skills.encode()), skills);
    });

    test('a unit taking nothing survives the round trip', () {
      final PartySkills skills =
          const PartySkills.empty().withUnit('ally_bramm', <String>[]);

      final PartySkills decoded = PartySkills.decode(skills.encode());

      expect(decoded.hasChoiceFor('ally_bramm'), isTrue);
      expect(decoded.forUnit('ally_bramm'), isEmpty);
    });

    test('no skills at all is an empty selection', () {
      expect(PartySkills.decode(null), const PartySkills.empty());
      expect(PartySkills.decode(''), const PartySkills.empty());
    });

    test('a hand-edited link keeps the entries it can still read', () {
      final PartySkills skills =
          PartySkills.decode('nonsense,ally_bramm:cleave,:mend');

      expect(skills.forUnit('ally_bramm'), <String>['cleave']);
      expect(skills.choices.length, 1);
    });

    test('a link naming one unit twice gives it one rotation', () {
      final PartySkills skills =
          PartySkills.decode('ally_bramm:cleave,ally_bramm:mend');

      expect(skills.forUnit('ally_bramm'), <String>['cleave']);
    });

    test('a link asking for more than a unit can carry is cut down', () {
      final PartySkills skills = PartySkills.decode(
        'ally_bramm:fortify.cleave.mend.rally.disrupt',
      );

      expect(skills.forUnit('ally_bramm')?.length, kChosenSkillSlots);
    });
  });

  test('two selections of the same skills are the same selection', () {
    expect(
      const PartySkills.empty().withUnit('ally_bramm', <String>['cleave']),
      const PartySkills.empty().withUnit('ally_bramm', <String>['cleave']),
    );
    expect(
      const PartySkills.empty().withUnit('ally_bramm', <String>['cleave']),
      isNot(
        const PartySkills.empty().withUnit('ally_bramm', <String>['mend']),
      ),
    );
  });
}
