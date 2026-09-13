import 'package:equatable/equatable.dart';

import 'stat.dart';

/// What kind of thing granted a modifier.
///
/// Only used for grouping and display — the maths treats every source
/// identically, which is the property that lets a buff and a breastplate share
/// one pipeline.
enum ModifierSourceKind { item, status, aura, trait, passive }

/// Where a modifier came from, and the handle used to take it away again.
///
/// Removal is always by source: unequipping a sword removes everything the
/// sword granted without anyone tracking which modifiers those were. That is
/// why a source has to be a value with equality rather than an object identity.
class ModifierSource extends Equatable {
  const ModifierSource({required this.kind, required this.id});

  const ModifierSource.item(this.id) : kind = ModifierSourceKind.item;

  const ModifierSource.status(this.id) : kind = ModifierSourceKind.status;

  const ModifierSource.aura(this.id) : kind = ModifierSourceKind.aura;

  const ModifierSource.trait(this.id) : kind = ModifierSourceKind.trait;

  const ModifierSource.passive(this.id) : kind = ModifierSourceKind.passive;

  final ModifierSourceKind kind;

  /// Unique within [kind] — a gear slot, a status id, a trait id.
  final String id;

  @override
  List<Object?> get props => <Object?>[kind, id];

  @override
  String toString() => '${kind.name}:$id';
}

/// One statement of the form "this source changes this stat by this much".
///
/// Authored as data: an item definition carries a list of these, and so does a
/// status. Neither knows anything about the other.
class StatModifier extends Equatable {
  const StatModifier({
    required this.stat,
    required this.op,
    required this.value,
    required this.source,
  });

  const StatModifier.flat(
    this.stat,
    this.value, {
    required this.source,
  }) : op = ModOp.flat;

  const StatModifier.increased(
    this.stat,
    this.value, {
    required this.source,
  }) : op = ModOp.increased;

  const StatModifier.more(
    this.stat,
    this.value, {
    required this.source,
  }) : op = ModOp.more;

  final Stat stat;
  final ModOp op;

  /// Flat modifiers are absolute; [ModOp.increased] and [ModOp.more] are
  /// fractions, so `0.1` means 10%.
  final double value;

  final ModifierSource source;

  /// Rebinds this modifier to a source, so a definition can be authored once
  /// and applied by whoever grants it.
  StatModifier from(ModifierSource newSource) => StatModifier(
        stat: stat,
        op: op,
        value: value,
        source: newSource,
      );

  @override
  List<Object?> get props => <Object?>[stat, op, value, source];

  @override
  String toString() => '$source ${stat.name} ${op.name} $value';
}
