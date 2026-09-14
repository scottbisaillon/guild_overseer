import 'package:equatable/equatable.dart';

/// A thing the player can hold a quantity of and spend.
///
/// Reputation is deliberately not here. It is listed beside these in
/// [[docs/systems/economy]], but it is never spent — it is a threshold that
/// unlocks tiers, and modelling it as a balance invites code that debits it.
/// It belongs to the reputation system, as a running total with milestones.
enum Currency {
  gold('Gold'),
  crystals('Crystals'),
  essence('Essence'),
  prestigeTokens('Prestige Tokens');

  const Currency(this.label);

  /// Human readable name used by the HUD.
  final String label;
}

/// An amount of money — either what the guild holds or what something costs.
///
/// One type for both, because a price and a balance are the same statement
/// with different intent, and writing them the same way is what makes
/// [canAfford] and [spend] read as arithmetic rather than as a rulebook. A
/// missing currency is zero, so `Purse.of({Currency.gold: 50})` is a complete
/// price for something that costs fifty gold and nothing else.
///
/// Immutable, and amounts are never negative: a purse cannot represent debt.
/// [spend] answers `null` rather than going below zero, which turns "can we
/// afford this?" and "take it then" into one operation the caller cannot
/// perform half of.
class Purse extends Equatable {
  /// Drops zero and negative entries, so equality means what it looks like:
  /// a purse holding `{gold: 0}` is the empty purse.
  factory Purse(Map<Currency, int> amounts) {
    final Map<Currency, int> kept = <Currency, int>{
      for (final MapEntry<Currency, int> entry in amounts.entries)
        if (entry.value > 0) entry.key: entry.value,
    };
    assert(
      amounts.values.every((int amount) => amount >= 0),
      'A purse cannot hold a negative amount. Spend through spend() instead.',
    );
    return Purse._(Map<Currency, int>.unmodifiable(kept));
  }

  const Purse._(this.amounts);

  const Purse.empty() : amounts = const <Currency, int>{};

  /// The common case, spelled shorter: `Purse.gold(250)`.
  factory Purse.gold(int amount) => Purse(<Currency, int>{Currency.gold: amount});

  final Map<Currency, int> amounts;

  bool get isEmpty => amounts.isEmpty;

  bool get isNotEmpty => amounts.isNotEmpty;

  /// How much of [currency] is in here. Zero when there is none, because
  /// "none" and "no entry" are the same statement.
  int of(Currency currency) => amounts[currency] ?? 0;

  bool canAfford(Purse cost) =>
      cost.amounts.entries.every((MapEntry<Currency, int> e) => of(e.key) >= e.value);

  /// This purse with [income] added. Used for loot, sales and refunds alike.
  Purse plus(Purse income) => Purse(<Currency, int>{
        for (final Currency currency in Currency.values)
          currency: of(currency) + income.of(currency),
      });

  /// This purse with [cost] taken out, or null when it does not cover it.
  ///
  /// The null is the point: there is no way to reach into a purse and take
  /// more than is in it, so no caller can forget the check and no balance can
  /// go negative.
  Purse? spend(Purse cost) {
    if (!canAfford(cost)) {
      return null;
    }
    return Purse(<Currency, int>{
      for (final Currency currency in Currency.values)
        currency: of(currency) - cost.of(currency),
    });
  }

  Map<String, int> toJson() => <String, int>{
        for (final MapEntry<Currency, int> entry in amounts.entries)
          entry.key.name: entry.value,
      };

  static Purse fromJson(Map<String, Object?>? json) {
    if (json == null) {
      return const Purse.empty();
    }
    return Purse(<Currency, int>{
      for (final Currency currency in Currency.values)
        if (json[currency.name] case final num amount) currency: amount.toInt(),
    });
  }

  @override
  List<Object?> get props => <Object?>[
        for (final Currency currency in Currency.values) of(currency),
      ];

  @override
  String toString() => amounts.isEmpty
      ? 'nothing'
      : amounts.entries
          .map((MapEntry<Currency, int> e) => '${e.value} ${e.key.label}')
          .join(', ');
}
