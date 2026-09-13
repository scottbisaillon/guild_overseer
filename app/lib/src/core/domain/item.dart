import 'stat_modifier.dart';

/// Where a piece of gear is worn.
///
/// One item per slot: the slot is both the rule about what may be worn at once
/// and the handle its modifiers are granted under, so taking a sword off never
/// needs a record of what the sword gave.
enum GearSlot {
  weapon('Weapon'),
  helm('Helm'),
  chest('Chest'),
  gloves('Gloves'),
  legs('Legs'),
  trinket('Trinket');

  const GearSlot(this.label);

  /// Human readable name used by the HUD.
  final String label;

  /// The source gear in this slot grants its modifiers under.
  ModifierSource get source => ModifierSource.item(name);
}

/// A piece of gear as authored: static data, never mutated at runtime.
///
/// An item is a slot and a list of modifiers, and that is the whole of it. It
/// does not know about damage, or skills, or who is wearing it — it states what
/// it changes, and the stat pipeline does the rest. That is why this stage
/// needed almost no new machinery: the mechanism arrived with the first one.
class ItemDefinition {
  const ItemDefinition({
    required this.id,
    required this.name,
    required this.slot,
    this.modifiers = const <StatModifier>[],
  });

  final String id;
  final String name;
  final GearSlot slot;

  /// Granted to the wearer while equipped. Authored against any source; the
  /// loadout rebinds them to the slot they are worn in.
  final List<StatModifier> modifiers;
}
