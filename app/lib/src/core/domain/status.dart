import 'game_time.dart';
import 'presentation.dart';
import 'skill_effect.dart';
import 'stat.dart';
import 'stat_block.dart';
import 'stat_modifier.dart';

/// What a status *is*, for effects that want to talk about a kind of thing
/// rather than name one.
///
/// Tags are how a cleanse says "remove a debuff" without listing every debuff
/// in the game, and how content added later is covered by rules written
/// earlier. Adding a tag is adding a value here.
enum StatusTag {
  /// Helps the unit carrying it.
  buff,

  /// Harms the unit carrying it. What a cleanse looks for.
  debuff,

  /// Physical damage over time.
  bleed,
}

/// What happens when a status is applied to a unit that already has it.
enum StackPolicy {
  /// The duration resets. Intensity does not change.
  refresh,

  /// A stack is added, up to the maximum, and the duration resets. Every stack
  /// grants the modifiers again and adds its share to each tick.
  stack,
}

/// A status as authored: static data, never mutated at runtime.
///
/// One shape covers buffs, debuffs and damage over time, because they differ
/// only in what they carry. A buff is modifiers with no ticks; a bleed is
/// ticks with no modifiers; something can be both.
/// Statuses and effects refer to each other — a status carries effects, and an
/// effect can apply a status — so the two files import each other. The cycle is
/// in the domain itself, not an accident of layout.
class StatusDefinition {
  const StatusDefinition({
    required this.id,
    required this.name,
    required this.duration,
    this.tags = const <StatusTag>{},
    this.modifiers = const <StatModifier>[],
    this.onTick = const <SkillEffect>[],
    this.tickInterval = 0,
    this.maxStacks = 1,
    this.policy = StackPolicy.refresh,
    this.presentation = PresentationSpec.none,
  });

  final String id;
  final String name;

  /// Seconds the status lasts from application or the last refresh.
  final double duration;

  final Set<StatusTag> tags;

  /// Granted to the carrier's [StatBlock] while this is active, once per stack,
  /// and removed wholesale when it ends. A status never has to remember what
  /// it changed — the source it was granted under is the handle.
  final List<StatModifier> modifiers;

  /// Effects resolved every [tickInterval] seconds against whoever is carrying
  /// this — how a damage over time is expressed.
  ///
  /// A tick is an ordinary effect run through the ordinary resolver, so a
  /// bleed scales, rolls, reports and kills exactly as a sword swing does,
  /// with no second damage path to keep in step.
  ///
  /// Bare effects rather than [EffectSpec]s, because a tick has nobody to
  /// choose: it lands on its carrier. A status that reached other people would
  /// be an aura, which is a different thing and not this one.
  final List<SkillEffect> onTick;

  /// Seconds between ticks. Zero means the status never ticks.
  final double tickInterval;

  final int maxStacks;
  final StackPolicy policy;

  /// How this reads when it lands.
  final PresentationSpec presentation;

  bool get ticks => tickInterval > 0 && onTick.isNotEmpty;

  bool hasTag(StatusTag tag) => tags.contains(tag);
}

/// A status actually on a unit, with its clock running.
class ActiveStatus {
  ActiveStatus({
    required this.definition,
    required this.sourceId,
    required this.sourceName,
    required this.statSnapshot,
    required this.stacks,
  }) : remaining = definition.duration;

  final StatusDefinition definition;

  /// Who applied it. Carried so a tick is attributed to the unit that caused
  /// it, which may by then be dead.
  final String sourceId;
  final String sourceName;

  /// The applier's scaling stats, read once when this was applied.
  ///
  /// A tick is as strong as the unit that caused it was at the time. That is
  /// deterministic, survives the applier dying mid-bleed, and spares a player
  /// working out why a bleed changed strength when somebody else's buff ran
  /// out.
  final Map<Stat, double> statSnapshot;

  String get id => definition.id;

  double remaining;
  int stacks;

  double _sinceTick = 0;

  bool get isExpired => remaining <= 0;

  /// Advances the clock, calling [onTick] once per whole tick interval elapsed.
  void advance(double dt, void Function(ActiveStatus status) onTick) {
    remaining = GameTime.countDown(remaining, dt);
    if (!definition.ticks) {
      return;
    }
    _sinceTick += dt;
    while (GameTime.hasElapsed(_sinceTick, definition.tickInterval)) {
      _sinceTick -= definition.tickInterval;
      onTick(this);
    }
  }
}

/// The statuses on one unit.
///
/// Owns the bookkeeping that makes a status reversible: modifiers go into the
/// unit's [StatBlock] under `status:<id>`, and ending the status removes that
/// source. Nothing has to remember which numbers a buff touched.
class StatusContainer {
  StatusContainer({required StatBlock stats, required void Function() onChanged})
      : _stats = stats,
        _onChanged = onChanged;

  final StatBlock _stats;

  /// Called after the carrier's stats change, so it can reconcile — health
  /// carries across a change in maximum as a fraction.
  final void Function() _onChanged;

  final List<ActiveStatus> _active = <ActiveStatus>[];

  /// In application order, which is the order ticks resolve in.
  Iterable<ActiveStatus> get active => List<ActiveStatus>.unmodifiable(_active);

  bool get isEmpty => _active.isEmpty;

  bool has(String id) => _active.any((ActiveStatus s) => s.id == id);

  ActiveStatus? byId(String id) {
    for (final ActiveStatus status in _active) {
      if (status.id == id) {
        return status;
      }
    }
    return null;
  }

  int stacksOf(String id) => byId(id)?.stacks ?? 0;

  /// Applies [definition], or reinforces it when already present.
  ///
  /// Returns the live status either way, so a caller can report what happened.
  ActiveStatus apply(
    StatusDefinition definition, {
    required String sourceId,
    required String sourceName,
    required Map<Stat, double> statSnapshot,
    int stacks = 1,
  }) {
    final ActiveStatus? existing = byId(definition.id);
    if (existing == null) {
      final ActiveStatus status = ActiveStatus(
        definition: definition,
        sourceId: sourceId,
        sourceName: sourceName,
        statSnapshot: statSnapshot,
        stacks: stacks.clamp(1, definition.maxStacks),
      );
      _active.add(status);
      _regrant(status);
      return status;
    }

    existing.remaining = definition.duration;
    if (definition.policy == StackPolicy.stack) {
      final int next =
          (existing.stacks + stacks).clamp(1, definition.maxStacks);
      if (next != existing.stacks) {
        existing.stacks = next;
        _regrant(existing);
      }
    }
    return existing;
  }

  /// Ends a status by id. Returns whether it was there.
  bool remove(String id) {
    final ActiveStatus? status = byId(id);
    if (status == null) {
      return false;
    }
    _end(status);
    return true;
  }

  /// Ends up to [count] statuses carrying any of [tags], oldest first.
  ///
  /// This is what a cleanse is: it names a kind, not a list, so it covers
  /// debuffs that did not exist when it was written.
  List<ActiveStatus> removeMatching(Set<StatusTag> tags, {int count = 1}) {
    final List<ActiveStatus> removed = <ActiveStatus>[];
    for (final ActiveStatus status in List<ActiveStatus>.of(_active)) {
      if (removed.length >= count) {
        break;
      }
      if (status.definition.tags.any(tags.contains)) {
        _end(status);
        removed.add(status);
      }
    }
    return removed;
  }

  /// Advances every status, reporting ticks and expiries in order.
  void advance(
    double dt, {
    required void Function(ActiveStatus status) onTick,
    required void Function(ActiveStatus status) onExpire,
  }) {
    if (_active.isEmpty) {
      return;
    }
    // A copy, because a tick may kill the carrier and a handler may change
    // what is on it.
    for (final ActiveStatus status in List<ActiveStatus>.of(_active)) {
      status.advance(dt, onTick);
    }
    for (final ActiveStatus status in List<ActiveStatus>.of(_active)) {
      if (status.isExpired) {
        _end(status);
        onExpire(status);
      }
    }
  }

  /// Drops everything without reporting, for a unit leaving the fight.
  void clear() {
    for (final ActiveStatus status in List<ActiveStatus>.of(_active)) {
      _end(status);
    }
  }

  ModifierSource _sourceFor(ActiveStatus status) =>
      ModifierSource.status(status.id);

  void _regrant(ActiveStatus status) {
    if (status.definition.modifiers.isEmpty) {
      return;
    }
    final ModifierSource source = _sourceFor(status);
    _stats.removeBySource(source);
    // Once per stack: flat and increased modifiers then sum, and a
    // multiplicative one compounds, each of which is what stacking should do.
    for (int i = 0; i < status.stacks; i++) {
      _stats.grant(status.definition.modifiers, source);
    }
    _onChanged();
  }

  void _end(ActiveStatus status) {
    _active.remove(status);
    if (status.definition.modifiers.isNotEmpty) {
      _stats.removeBySource(_sourceFor(status));
      _onChanged();
    }
  }
}
