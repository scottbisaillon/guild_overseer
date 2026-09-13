import 'package:flutter_test/flutter_test.dart';
import 'package:guild_overseer/src/features/battle/domain/party_formation.dart';

void main() {
  const FormationSlot front = (row: 0, column: 0);
  const FormationSlot middle = (row: 1, column: 0);
  const FormationSlot back = (row: 0, column: 1);

  group('placing', () {
    test('a unit stands where it was put', () {
      final PartyFormation party =
          const PartyFormation.empty().place('bramm', front);

      expect(party.at(front), 'bramm');
      expect(party.slotOf('bramm'), front);
      expect(party.size, 1);
    });

    test('a unit stands in one place at a time', () {
      final PartyFormation party = const PartyFormation.empty()
          .place('bramm', front)
          .place('bramm', back);

      expect(party.at(front), isNull);
      expect(party.at(back), 'bramm');
      expect(party.size, 1);
    });

    test('two placed units dropped onto each other trade places', () {
      final PartyFormation party = const PartyFormation.empty()
          .place('bramm', front)
          .place('fenn', back)
          .place('fenn', front);

      expect(party.at(front), 'fenn');
      expect(party.at(back), 'bramm');
      expect(party.size, 2);
    });

    test('a benched unit dropped onto an occupied slot takes it', () {
      // Nowhere to swap the occupant to, so it goes back to the bench rather
      // than being carried somewhere the player did not ask for.
      final PartyFormation party = const PartyFormation.empty()
          .place('bramm', front)
          .place('kessa', front);

      expect(party.at(front), 'kessa');
      expect(party.contains('bramm'), isFalse);
      expect(party.size, 1);
    });

    test('placing a unit back where it already stands changes nothing', () {
      final PartyFormation party =
          const PartyFormation.empty().place('bramm', front);

      expect(party.place('bramm', front), same(party));
    });
  });

  group('removing', () {
    test('clearing a slot benches whoever stood in it', () {
      final PartyFormation party = const PartyFormation.empty()
          .place('bramm', front)
          .place('fenn', back)
          .clearSlot(front);

      expect(party.contains('bramm'), isFalse);
      expect(party.at(back), 'fenn');
    });

    test('a unit can be benched without knowing where it stands', () {
      final PartyFormation party =
          const PartyFormation.empty().place('bramm', middle).remove('bramm');

      expect(party.isEmpty, isTrue);
    });

    test('removing somebody who is not placed changes nothing', () {
      final PartyFormation party =
          const PartyFormation.empty().place('bramm', front);

      expect(party.remove('nobody'), same(party));
    });
  });

  group('order', () {
    test('units come out front line first, top to bottom', () {
      final PartyFormation party = const PartyFormation.empty()
          .place('back_top', (row: 0, column: 1))
          .place('front_bottom', (row: 2, column: 0))
          .place('front_top', (row: 0, column: 0));

      expect(
        party.orderedUnitIds(),
        <String>['front_top', 'front_bottom', 'back_top'],
      );
    });
  });

  group('links', () {
    test('a formation survives the round trip through a URL', () {
      final PartyFormation party = const PartyFormation.empty()
          .place('ally_bramm', front)
          .place('ally_fenn', back)
          .place('ally_kessa', middle);

      expect(PartyFormation.decode(party.encode()), party);
    });

    test('an empty formation encodes to nothing and back', () {
      expect(const PartyFormation.empty().encode(), '');
      expect(PartyFormation.decode(''), const PartyFormation.empty());
      expect(PartyFormation.decode(null), const PartyFormation.empty());
    });

    test('the encoding is readable, which is the point of it', () {
      final PartyFormation party = const PartyFormation.empty()
          .place('ally_bramm', front)
          .place('ally_fenn', back);

      expect(party.encode(), 'ally_bramm:0:0,ally_fenn:0:1');
    });

    test('a hand-mangled link keeps what it can and drops the rest', () {
      final PartyFormation party = PartyFormation.decode(
        'ally_bramm:0:0,nonsense,ally_fenn:9:9,:1:1,ally_mira:x:0,'
        'ally_kessa:1:0',
      );

      expect(party.at(front), 'ally_bramm');
      expect(party.at(middle), 'ally_kessa');
      expect(party.size, 2);
    });

    test('a link cannot put one unit in two slots, or two in one', () {
      final PartyFormation party = PartyFormation.decode(
        'ally_bramm:0:0,ally_bramm:1:0,ally_fenn:0:0',
      );

      expect(party.at(front), 'ally_bramm');
      expect(party.size, 1);
    });
  });
}
