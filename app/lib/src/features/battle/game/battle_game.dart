import 'dart:async';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';

import '../../../core/domain/skill_kind.dart';
import '../../../core/events/game_event.dart';
import '../domain/arena_layout.dart';
import '../domain/battle_simulation.dart';
import '../domain/combatant.dart';
import '../view/battle_palette.dart';
import 'components/arena_background_component.dart';
import 'components/floating_text_component.dart';
import 'components/projectile_component.dart';
import 'components/target_lines_component.dart';
import 'components/unit_component.dart';

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
        // combatant, and the rest is HUD-only state.
        break;
    }
  }

  void _onSkillFired(SkillFired event) {
    final UnitComponent? source = _unitComponents[event.sourceId];
    if (source == null || event.targetIds.isEmpty) {
      return;
    }
    final Vector2 origin = _positionOf(event.sourceId);
    source.playCast(event.delivery, _positionOf(event.targetIds.first));

    final Color color = event.kind == SkillKind.heal
        ? BattlePalette.heal
        : BattlePalette.faction(
            simulation.unitById(event.sourceId)!.faction,
          );

    for (final String targetId in event.targetIds) {
      final Vector2 target = _positionOf(targetId);
      switch (event.delivery) {
        case SkillDelivery.projectile:
          world.add(
            ProjectileComponent(from: origin, to: target, color: color),
          );
        case SkillDelivery.beam:
          world.add(BeamComponent(from: origin, to: target, color: color));
        case SkillDelivery.melee:
          // The lunge is the effect; a second flourish only adds noise.
          break;
      }
    }
  }

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
