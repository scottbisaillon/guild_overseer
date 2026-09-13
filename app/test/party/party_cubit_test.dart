import 'package:flutter_test/flutter_test.dart';
import 'package:guild_overseer/src/features/battle/domain/party_formation.dart';
import 'package:guild_overseer/src/features/party/cubit/party_cubit.dart';
import 'package:guild_overseer/src/features/party/cubit/party_state.dart';

void main() {
  const FormationSlot front = (row: 0, column: 0);
  const FormationSlot back = (row: 0, column: 1);

  group('select and place', () {
    test('a tapped unit is held, and placed by the next tapped slot', () {
      final PartyCubit cubit = PartyCubit()
        ..tapUnit('bramm')
        ..tapSlot(front);

      expect(cubit.state.formation.at(front), 'bramm');
      expect(cubit.state.heldUnitId, isNull);
    });

    test('tapping a held unit again puts it back down', () {
      final PartyCubit cubit = PartyCubit()
        ..tapUnit('bramm')
        ..tapUnit('bramm');

      expect(cubit.state.heldUnitId, isNull);
      expect(cubit.state.formation.isEmpty, isTrue);
    });

    test('an empty hand on an occupied slot picks that unit up', () {
      final PartyCubit cubit = PartyCubit()
        ..tapUnit('bramm')
        ..tapSlot(front)
        ..tapSlot(front);

      expect(cubit.state.heldUnitId, 'bramm');
      // Picked up, not moved: an abandoned move leaves the board as it was.
      expect(cubit.state.formation.at(front), 'bramm');
    });

    test('a picked up unit moves when it is put down again', () {
      final PartyCubit cubit = PartyCubit()
        ..tapUnit('bramm')
        ..tapSlot(front)
        ..tapSlot(front)
        ..tapSlot(back);

      expect(cubit.state.formation.at(back), 'bramm');
      expect(cubit.state.formation.at(front), isNull);
    });

    test('an empty hand on an empty slot does nothing at all', () {
      final PartyCubit cubit = PartyCubit()..tapSlot(front);

      expect(cubit.state, const PartyState.initial());
    });
  });

  group('drag and drop', () {
    test('a dropped unit lands in the slot it was dropped on', () {
      final PartyCubit cubit = PartyCubit()..dropOnSlot('fenn', back);

      expect(cubit.state.formation.at(back), 'fenn');
    });

    test('a drop settles whatever was being held', () {
      final PartyCubit cubit = PartyCubit()
        ..tapUnit('bramm')
        ..dropOnSlot('fenn', back);

      expect(cubit.state.heldUnitId, isNull);
      expect(cubit.state.formation.at(back), 'fenn');
      expect(cubit.state.formation.contains('bramm'), isFalse);
    });
  });

  group('taking units back off', () {
    test('benching a unit removes it and drops it from the hand', () {
      final PartyCubit cubit = PartyCubit()
        ..dropOnSlot('bramm', front)
        ..tapSlot(front)
        ..bench('bramm');

      expect(cubit.state.formation.isEmpty, isTrue);
      expect(cubit.state.heldUnitId, isNull);
    });

    test('clearing a slot leaves the rest of the party standing', () {
      final PartyCubit cubit = PartyCubit()
        ..dropOnSlot('bramm', front)
        ..dropOnSlot('fenn', back)
        ..clearSlot(front);

      expect(cubit.state.formation.at(back), 'fenn');
      expect(cubit.state.placedCount, 1);
    });

    test('clearing everything empties the board and the hand', () {
      final PartyCubit cubit = PartyCubit()
        ..dropOnSlot('bramm', front)
        ..tapUnit('fenn')
        ..clearAll();

      expect(cubit.state, const PartyState.initial());
      expect(cubit.state.canDispatch, isFalse);
    });
  });

  test('a party can be handed in whole, ready to dispatch', () {
    final PartyFormation party =
        const PartyFormation.empty().place('bramm', front);
    final PartyCubit cubit = PartyCubit()..reset(party);

    expect(cubit.state.formation, party);
    expect(cubit.state.canDispatch, isTrue);
  });

  test('a cubit can open on a party, for a link that carries one', () {
    final PartyFormation party =
        const PartyFormation.empty().place('bramm', back);

    expect(PartyCubit(formation: party).state.formation, party);
  });
}
