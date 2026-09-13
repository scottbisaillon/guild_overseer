import 'item.dart';
import 'stat_block.dart';

/// What a unit is wearing.
///
/// The same bookkeeping a status does, for the same reason and through the same
/// pipeline: modifiers go in under the slot, and taking the item off removes
/// that source. Nothing has to remember which numbers a breastplate touched, and
/// the combat maths never learns that gear exists.
class Loadout {
  Loadout(this._stats, this._onChanged);

  final StatBlock _stats;

  /// Called after the wearer's stats change, so it can reconcile — health
  /// carries across a change in maximum as a fraction.
  final void Function() _onChanged;

  final Map<GearSlot, ItemDefinition> _worn = <GearSlot, ItemDefinition>{};

  Map<GearSlot, ItemDefinition> get worn =>
      Map<GearSlot, ItemDefinition>.unmodifiable(_worn);

  bool get isEmpty => _worn.isEmpty;

  ItemDefinition? itemIn(GearSlot slot) => _worn[slot];

  /// Puts [item] on, taking off whatever occupied its slot.
  ///
  /// Returns the item that came off, so a caller can put it back in the stash.
  ItemDefinition? equip(ItemDefinition item) {
    final ItemDefinition? replaced = _remove(item.slot);
    _worn[item.slot] = item;
    _stats.grant(item.modifiers, item.slot.source);
    _onChanged();
    return replaced;
  }

  /// Takes off whatever is in [slot], returning it. Null when the slot is bare,
  /// which is not an error.
  ItemDefinition? unequip(GearSlot slot) {
    final ItemDefinition? removed = _remove(slot);
    if (removed != null) {
      _onChanged();
    }
    return removed;
  }

  void clear() {
    for (final GearSlot slot in _worn.keys.toList()) {
      _remove(slot);
    }
    _onChanged();
  }

  ItemDefinition? _remove(GearSlot slot) {
    final ItemDefinition? removed = _worn.remove(slot);
    if (removed != null) {
      _stats.removeBySource(slot.source);
    }
    return removed;
  }
}
