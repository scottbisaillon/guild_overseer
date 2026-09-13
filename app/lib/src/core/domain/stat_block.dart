import 'stat.dart';
import 'stat_modifier.dart';

/// Every number about one unit, and everything currently changing them.
///
/// The one pipeline all sources feed. A buff, a breastplate, an aura and a
/// trait are indistinguishable once they are in here — they differ only by the
/// [ModifierSource] they were added under, which is how they are taken away
/// again and how a tooltip groups them.
///
/// Evaluation order is fixed and deliberately boring:
///
/// ```
/// (base + Σflat) × (1 + Σincreased) × Π(1 + more)   then clamped
/// ```
///
/// Fixed order means the sequence modifiers arrived in cannot change the
/// answer, so two units with the same gear and buffs always have the same
/// stats regardless of what happened to them in what order.
class StatBlock {
  StatBlock([Map<Stat, double>? base])
      : _base = <Stat, double>{...?base};

  final Map<Stat, double> _base;

  final List<StatModifier> _modifiers = <StatModifier>[];

  /// Computed values, dropped per stat as modifiers touching it change.
  /// Stats are read every frame by the simulation and change rarely, so the
  /// cache is doing real work rather than guarding against a cheap sum.
  final Map<Stat, double> _cache = <Stat, double>{};

  /// The unmodified value: what this unit was authored with.
  double base(Stat stat) => _base[stat] ?? stat.defaultValue;

  /// The value after everything currently affecting the unit.
  double value(Stat stat) => _cache[stat] ??= _compute(stat);

  /// Every modifier in play, in the order it was added.
  Iterable<StatModifier> get modifiers =>
      List<StatModifier>.unmodifiable(_modifiers);

  /// Everything one source is granting — the tooltip query.
  Iterable<StatModifier> fromSource(ModifierSource source) =>
      _modifiers.where((StatModifier m) => m.source == source);

  bool hasSource(ModifierSource source) =>
      _modifiers.any((StatModifier m) => m.source == source);

  /// Replaces the authored value for a stat. Levelling and class bases go
  /// through here; temporary changes should be modifiers instead, so they can
  /// be removed without anyone remembering the old number.
  void setBase(Stat stat, double value) {
    _base[stat] = value;
    _cache.remove(stat);
  }

  void add(StatModifier modifier) {
    _modifiers.add(modifier);
    _cache.remove(modifier.stat);
  }

  void addAll(Iterable<StatModifier> modifiers) {
    for (final StatModifier modifier in modifiers) {
      add(modifier);
    }
  }

  /// Adds [modifiers] rebound to [source], so an item or status definition can
  /// be authored once and granted by whoever is granting it.
  void grant(Iterable<StatModifier> modifiers, ModifierSource source) =>
      addAll(modifiers.map((StatModifier m) => m.from(source)));

  /// Removes everything [source] granted. Returns how many were removed, which
  /// is zero when the source was not granting anything — unequipping an empty
  /// slot is not an error.
  int removeBySource(ModifierSource source) {
    final int before = _modifiers.length;
    final Set<Stat> touched = <Stat>{};
    _modifiers.removeWhere((StatModifier m) {
      if (m.source != source) {
        return false;
      }
      touched.add(m.stat);
      return true;
    });
    for (final Stat stat in touched) {
      _cache.remove(stat);
    }
    return before - _modifiers.length;
  }

  void clearModifiers() {
    _modifiers.clear();
    _cache.clear();
  }

  /// What each source contributes to [stat], for a tooltip that explains where
  /// a number came from. The values are not additive across rows — they are
  /// the modifiers as authored — but the grouping is what a player asks for.
  Map<ModifierSource, List<StatModifier>> breakdown(Stat stat) {
    final Map<ModifierSource, List<StatModifier>> out =
        <ModifierSource, List<StatModifier>>{};
    for (final StatModifier modifier in _modifiers) {
      if (modifier.stat != stat) {
        continue;
      }
      (out[modifier.source] ??= <StatModifier>[]).add(modifier);
    }
    return out;
  }

  double _compute(Stat stat) {
    double flat = 0;
    double increased = 0;
    double more = 1;

    for (final StatModifier modifier in _modifiers) {
      if (modifier.stat != stat) {
        continue;
      }
      switch (modifier.op) {
        case ModOp.flat:
          flat += modifier.value;
        case ModOp.increased:
          increased += modifier.value;
        case ModOp.more:
          more *= 1 + modifier.value;
      }
    }

    return stat.clamp((base(stat) + flat) * (1 + increased) * more);
  }

  @override
  String toString() => 'StatBlock(${_modifiers.length} modifiers)';
}
