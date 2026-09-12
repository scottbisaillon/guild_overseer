import 'dart:async';
import 'dart:math' as math;

import '../../../core/domain/combat_snapshot.dart';
import '../../../core/domain/faction.dart';
import '../../../core/domain/skill_kind.dart';
import '../../../core/events/game_event.dart';
import 'arena_layout.dart';
import 'combatant.dart';
import 'rotation.dart';
import 'skill.dart';
import 'targeting.dart';

/// Builds a fresh set of combatants. Called again on every restart so a rerun
/// starts from identical state.
typedef RosterBuilder = List<Combatant> Function();

/// The fight itself, with no engine attached.
///
/// [update] is driven by the Flame game loop in the app and by a plain loop in
/// tests — the simulation cannot tell the difference. Everything it decides is
/// published to [events]; nothing reads back out of the renderer.
class BattleSimulation {
  BattleSimulation({
    required RosterBuilder rosterBuilder,
    this.layout = const ArenaLayout(),
    this.seed = 20260912,
    this.sampleInterval = 0.1,
    this.maxStep = 1 / 60,
  })  : _rosterBuilder = rosterBuilder,
        _units = rosterBuilder(),
        _random = math.Random(seed);

  final RosterBuilder _rosterBuilder;
  final ArenaLayout layout;

  /// Fixed seed: the same roster fought twice produces the same fight, which
  /// makes the mockup reproducible and the tests deterministic.
  final int seed;

  /// How often continuous state (health, cooldowns) is published.
  final double sampleInterval;

  /// Longest slice of simulated time resolved in one step. Larger frame times
  /// are split, so a stutter or a 4x speed setting cannot skip a beat.
  final double maxStep;

  final StreamController<GameEvent> _events =
      StreamController<GameEvent>.broadcast();

  List<Combatant> _units;
  math.Random _random;

  BattleStatus _status = BattleStatus.notStarted;
  Faction? _winner;
  double _speed = 1;
  double _elapsed = 0;
  double _sampleAccumulator = 0;

  /// Simulated time banked by [update] but not yet spent on a whole step.
  double _stepAccumulator = 0;

  /// The one channel out of the simulation. The Flame layer listens to spawn
  /// effects; the Bloc listens to build HUD state.
  Stream<GameEvent> get events => _events.stream;

  List<Combatant> get units => List<Combatant>.unmodifiable(_units);

  BattleStatus get status => _status;

  Faction? get winner => _winner;

  double get speed => _speed;

  double get elapsed => _elapsed;

  bool get isRunning => _status == BattleStatus.running;

  Combatant? unitById(String? id) {
    if (id == null) {
      return null;
    }
    for (final Combatant unit in _units) {
      if (unit.id == id) {
        return unit;
      }
    }
    return null;
  }

  void start() {
    if (_status != BattleStatus.notStarted) {
      return;
    }
    _status = BattleStatus.running;
    _emit(const BattleStarted());
    _emitSample();
  }

  void pause() {
    if (_status != BattleStatus.running) {
      return;
    }
    _status = BattleStatus.paused;
    _emit(const BattlePaused());
    _emitSample();
  }

  void resume() {
    if (_status != BattleStatus.paused) {
      return;
    }
    _status = BattleStatus.running;
    _emit(const BattleResumed());
    _emitSample();
  }

  /// Rebuilds the roster and replays the same fight from the top.
  void restart() {
    _units = _rosterBuilder();
    _random = math.Random(seed);
    _status = BattleStatus.running;
    _winner = null;
    _elapsed = 0;
    _sampleAccumulator = 0;
    _stepAccumulator = 0;
    _emit(const BattleReset());
    _emit(const BattleStarted());
    _emitSample();
  }

  void setSpeed(double speed) {
    _speed = speed.clamp(0.25, 8.0);
    _emitSample();
  }

  /// Advances the fight by [dt] seconds of real time, scaled by [speed].
  ///
  /// The fight only ever moves in whole [maxStep] slices. Time left over at the
  /// end of a frame is banked and spent on the next one, so the outcome depends
  /// on how much time has passed and not on how it was delivered: 60Hz, 120Hz,
  /// a stuttering frame and the test harness all resolve the same fight. Paying
  /// out the remainder as a short ragged step instead would move every cooldown
  /// boundary by a sliver and quietly make the rendered fight a different fight
  /// from the recorded one.
  void update(double dt) {
    if (_status != BattleStatus.running || dt <= 0) {
      return;
    }
    // A long frame (first frame, a resize, a backgrounded app) must not fast
    // forward the fight, so the raw delta is capped before scaling.
    _stepAccumulator += math.min(dt, 0.25) * _speed;
    while (_stepAccumulator >= maxStep && _status == BattleStatus.running) {
      _step(maxStep);
      _stepAccumulator -= maxStep;
    }
  }

  void _step(double dt) {
    _elapsed += dt;

    for (final Combatant unit in _units) {
      if (unit.isAlive) {
        unit.tickCooldowns(dt);
      }
    }

    _acquireTargets();
    _act();
    _checkForEnd();

    _sampleAccumulator += dt;
    if (_sampleAccumulator >= sampleInterval) {
      _sampleAccumulator = 0;
      _emitSample();
    }
  }

  /// A unit keeps its target until that target dies or leaves the fight; only
  /// then does it look for a new one.
  void _acquireTargets() {
    for (final Combatant unit in _units) {
      if (!unit.isAlive) {
        continue;
      }
      final Combatant? current = unitById(unit.targetId);
      if (current != null && current.isAlive) {
        continue;
      }
      final Combatant? next = selectTarget(
        unit: unit,
        candidates: _units,
        layout: layout,
      );
      unit.targetId = next?.id;
      if (next != null) {
        _emit(TargetAcquired(
          unitId: unit.id,
          unitName: unit.name,
          targetId: next.id,
          targetName: next.name,
        ));
      }
    }
  }

  void _act() {
    for (final Combatant unit in _units) {
      // A unit killed earlier in this same step does not get to act.
      if (!unit.isAlive) {
        continue;
      }
      final RotationDecision? decision = selectSkill(
        unit: unit,
        currentTarget: unitById(unit.targetId),
        units: _units,
      );
      if (decision == null) {
        continue;
      }
      _fire(unit, decision);
    }
  }

  void _fire(Combatant unit, RotationDecision decision) {
    final SkillDefinition skill = decision.skill;
    decision.slot.trigger();
    unit.startGlobalCooldown();

    _emit(SkillFired(
      sourceId: unit.id,
      sourceName: unit.name,
      targetIds:
          decision.targets.map((Combatant c) => c.id).toList(growable: false),
      skillId: skill.id,
      skillName: skill.name,
      kind: skill.kind,
      delivery: skill.delivery,
    ));

    for (final Combatant target in decision.targets) {
      final double amount = _roll(skill.power);
      switch (skill.kind) {
        case SkillKind.damage:
          final double dealt = target.applyDamage(amount);
          _emit(DamageDealt(
            sourceId: unit.id,
            sourceName: unit.name,
            targetId: target.id,
            targetName: target.name,
            skillName: skill.name,
            amount: dealt,
            remainingHealth: target.health,
          ));
          if (!target.isAlive) {
            _emit(UnitDied(
              unitId: target.id,
              unitName: target.name,
              faction: target.faction,
            ));
          }
        case SkillKind.heal:
          final double healed = target.applyHeal(amount);
          _emit(HealApplied(
            sourceId: unit.id,
            sourceName: unit.name,
            targetId: target.id,
            targetName: target.name,
            skillName: skill.name,
            amount: healed,
            remainingHealth: target.health,
          ));
      }
    }
  }

  /// Damage and healing land within +/-15% of the authored power, rounded to
  /// whole numbers so the floating combat text stays readable.
  double _roll(double power) {
    final double variance = 0.85 + _random.nextDouble() * 0.3;
    return (power * variance).roundToDouble();
  }

  void _checkForEnd() {
    final bool alliesAlive = _units.any(
      (Combatant c) => c.faction == Faction.ally && c.isAlive,
    );
    final bool enemiesAlive = _units.any(
      (Combatant c) => c.faction == Faction.enemy && c.isAlive,
    );
    if (alliesAlive && enemiesAlive) {
      return;
    }
    _status = BattleStatus.finished;
    // A mutual wipe counts as a win for the side that still has someone left;
    // with nobody left at all, the party is the one that failed to clear.
    _winner = enemiesAlive ? Faction.enemy : Faction.ally;
    _emitSample();
    _emit(BattleEnded(_winner!));
  }

  BattleSnapshot snapshot() => BattleSnapshot(
        status: _status,
        elapsed: _elapsed,
        winner: _winner,
        units: <UnitSnapshot>[
          for (final Combatant unit in _units)
            unit.toSnapshot(targetName: unitById(unit.targetId)?.name),
        ],
      );

  void _emitSample() => _emit(BattleSampled(snapshot()));

  void _emit(GameEvent event) {
    if (!_events.isClosed) {
      _events.add(event);
    }
  }

  Future<void> dispose() => _events.close();
}
