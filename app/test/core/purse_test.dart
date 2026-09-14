import 'package:flutter_test/flutter_test.dart';
import 'package:guild_overseer/src/core/domain/purse.dart';

/// Spending is the operation worth pinning: the type's job is that no caller
/// can take more out than is in it.
void main() {
  const Purse empty = Purse.empty();

  group('Purse', () {
    test('a currency with no entry reads as none of it', () {
      expect(empty.of(Currency.gold), 0);
    });

    test('zero entries are dropped, so equality means what it looks like', () {
      expect(Purse(<Currency, int>{Currency.gold: 0}), empty);
    });

    test('income adds per currency', () {
      final Purse held = Purse.gold(100).plus(
        Purse(<Currency, int>{Currency.gold: 50, Currency.essence: 3}),
      );

      expect(held.of(Currency.gold), 150);
      expect(held.of(Currency.essence), 3);
    });

    test('affording needs every currency in the price, not just one', () {
      final Purse held = Purse.gold(500);
      final Purse price =
          Purse(<Currency, int>{Currency.gold: 100, Currency.crystals: 1});

      expect(held.canAfford(Purse.gold(100)), isTrue);
      expect(held.canAfford(price), isFalse);
    });

    test('spending what is there takes exactly that much', () {
      final Purse? left = Purse(<Currency, int>{
        Currency.gold: 500,
        Currency.essence: 10,
      }).spend(Purse.gold(120));

      expect(left, isNotNull);
      expect(left!.of(Currency.gold), 380);
      expect(left.of(Currency.essence), 10);
    });

    test('spending more than is there answers null and takes nothing', () {
      expect(Purse.gold(50).spend(Purse.gold(51)), isNull);
    });

    test('spending everything leaves the empty purse', () {
      expect(Purse.gold(50).spend(Purse.gold(50)), empty);
    });

    test('round-trips through json', () {
      final Purse held = Purse(<Currency, int>{
        Currency.gold: 900,
        Currency.prestigeTokens: 2,
      });

      expect(Purse.fromJson(held.toJson()), held);
    });
  });
}
