import 'dart:async';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';

import '../../../core/domain/cue_registry.dart';
import '../../../core/domain/presentation.dart';
import '../../../core/events/game_event.dart';
import '../domain/arena_layout.dart';
import '../domain/battle_simulation.dart';
import '../domain/combatant.dart';
import '../view/battle_palette.dart';
import 'components/arena_background_component.dart';
import 'components/floating_text_component.dart';
import 'components/target_lines_component.dart';
import 'components/unit_component.dart';
import 'cues/battle_cues.dart';

/// The Flame layer: it draws the fight and nothing else.
///
/// The game owns no combat rules. It drives [BattleSimulation.update] from the
/// engine's frame loop, then reacts to the events the simulation publishes by
/// spawning effects. Swapping this renderer out would not change the outcome of
/// a single fight — which is what makes the simulation testable headlessly.
class BattleGame extends FlameGame {
  BattleGame({required this.simulation})
      : super(
          camera: CameraComponent.withFixedResolution(
            width: kArenaLayout.width,
            height: kArenaLayout.height,
          ),
        );

  final BattleSimulation simulation;

  /// Draw a line from each unit to its current target.
  bool showTargetLines = true;

  final Map<String, UnitComponent> _unitComponents = <String, UnitComponent>{};

  /// Cue id -> what draws it. The only thing standing between what content
  /// asks for and what appears on screen.
  final CueRegistry<CueContext> _cues = buildBattleCues();

  StreamSubscription<GameEvent>? _subscription;

  ArenaLayout get layout => simulation.layout;

  @override
  Color backgroundColor() => BattlePalette.background;

  @override
  Future<void> onLoad() async {
    // The fixed-resolution viewport maps arena space onto the widget, and the
    // viewfinder is parked on the middle of the arena so (0,0) lands in the
    // top-left corner rather than the centre of the screen.
    camera.viewfinder.position = Vector2(layout.centreX, layout.centreY);

    await world.add(ArenaBackgroundComponent(layout: layout));
    await world.add(
      TargetLinesComponent(simulation: simulation, layout: layout),
    );
    await _spawnUnits();
    _subscription = simulation.events.listen(_onGameEvent);
  }

  @override
  void onRemove() {
    _subscription?.cancel();
    super.onRemove();
  }

  @override
  void update(double dt) {
    // Rules first, presentation second: components read unit state that is
    // already settled for this frame.
    simulation.update(dt);
    super.update(dt);
  }

  /// Rebuilds the arena after the simulation was reset.
  Future<void> rebuild() async {
    for (final UnitComponent component in _unitComponents.values) {
      component.removeFromParent();
    }
    _unitComponents.clear();
    await _spawnUnits();
  }

  Future<void> _spawnUnits() async {
    for (final Combatant combatant in simulation.units) {
      final UnitComponent component =
          UnitComponent(combatant: combatant, layout: layout);
      _unitComponents[combatant.id] = component;
      await world.add(component);
    }
  }

  Vector2 _positionOf(String unitId) {
    final Combatant? combatant = simulation.unitById(unitId);
    if (combatant == null) {
      return Vector2(layout.centreX, layout.centreY);
    }
    final ArenaPoint point = combatant.position(layout);
    return Vector2(point.x, point.y);
  }

  void _onGameEvent(GameEvent event) {
    switch (event) {
      case SkillFired():
        _onSkillFired(event);
      case DamageDealt(:final targetId, :final amount):
        _unitComponents[targetId]?.playHit();
        _spawnFloatingText(
          targetId,
          '-${amount.toStringAsFixed(0)}',
          BattlePalette.damage,
        );
      case HealApplied(:final targetId, :final amount):
        _spawnFloatingText(
          targetId,
          '+${amount.toStringAsFixed(0)}',
          BattlePalette.heal,
        );
      case StatusApplied():
        _onStatusApplied(event);
      case StatusEnded():
      case UnitDied():
      case BattleStarted():
      case BattlePaused():
      case BattleResumed():
      case BattleReset():
      case BattleEnded():
      case TargetAcquired():
      case BattleSampled():
      case StartBattleRequested():
      case PauseBattleRequested():
      case ResumeBattleRequested():
      case RestartBattleRequested():
      case SpeedChangeRequested():
        // Nothing to draw: unit components read death straight off the
        // combatant, a status ending is not worth an effect, and the rest is
        // HUD-only state.
        break;
    }
  }

  void _onSkillFired(SkillFired event) {
    final UnitComponent? source = _unitComponents[event.sourceId];
    if (source == null || event.targetIds.isEmpty) {
      return;
    }
    source.playCast();

    final PresentationSpec spec = event.presentation;
    final Vector2 origin = _positionOf(event.sourceId);
    final Color color = _colorFor(spec.color, event.sourceId);

    // One cast and one area, then travel and impact once per target. No branch
    // on what kind of skill this was: the spec names cues and the registry
    // resolves them, so a new visual never reaches this method.
    _cues.play(
      spec.cast,
      CueContext(
        world: world,
        origin: origin,
        destination: _positionOf(event.targetIds.first),
        color: color,
        source: source,
      ),
    );

    // The ground the skill covered, handed over as the cells it reached. What
    // shape those add up to is the cue's business, and which shape the skill
    // asked for is the simulation's; neither has to tell the other.
    _cues.play(
      spec.area,
      CueContext(
        world: world,
        origin: origin,
        destination: _positionOf(event.targetIds.first),
        color: color,
        source: source,
        cells: <Rect>[
          for (final String targetId in event.targetIds)
            if (_cellOf(targetId) case final Rect cell) cell,
        ],
      ),
    );
    for (final String targetId in event.targetIds) {
      final CueContext context = CueContext(
        world: world,
        origin: origin,
        destination: _positionOf(targetId),
        color: color,
        source: source,
        target: _unitComponents[targetId],
      );
      _cues.play(spec.travel, context);
      _cues.play(spec.impact, context);
    }
  }

  /// The cell [unitId] is standing in, or null when the renderer cannot place
  /// it — a unit that left the fight between the event and the frame drawing
  /// it contributes no ground rather than a footprint at the origin.
  Rect? _cellOf(String unitId) {
    final Combatant? combatant = simulation.unitById(unitId);
    if (combatant == null) {
      return null;
    }
    final ArenaPoint point = combatant.position(layout);
    return Rect.fromCenter(
      center: Offset(point.x, point.y),
      width: layout.cellSize,
      height: layout.cellSize,
    );
  }

  void _onStatusApplied(StatusApplied event) {
    final PresentationSpec spec = event.presentation;
    final Vector2 at = _positionOf(event.targetId);
    _cues.play(
      spec.impact,
      CueContext(
        world: world,
        origin: at,
        destination: at,
        color: _colorFor(spec.color, event.targetId),
        target: _unitComponents[event.targetId],
        label: event.statusName,
      ),
    );
  }

  /// What an authored colour role means in this palette.
  ///
  /// Falls back rather than asserting: presentation never gets to be the reason
  /// a fight stops, so a unit the renderer cannot find is drawn in a neutral
  /// colour instead of crashing the frame.
  Color _colorFor(CueColor role, String unitId) => switch (role) {
        CueColor.source => switch (simulation.unitById(unitId)) {
            final Combatant unit => BattlePalette.faction(unit.faction),
            null => BattlePalette.textMuted,
          },
        CueColor.heal => BattlePalette.heal,
        CueColor.damage => BattlePalette.damage,
        CueColor.buff => BattlePalette.heal,
        CueColor.debuff => BattlePalette.damage,
      };

  void _spawnFloatingText(String unitId, String text, Color color) {
    final Vector2 position = _positionOf(unitId);
    world.add(
      FloatingTextComponent(
        text: text,
        color: color,
        position: position - Vector2(0, layout.cellSize / 2),
      ),
    );
  }
}
