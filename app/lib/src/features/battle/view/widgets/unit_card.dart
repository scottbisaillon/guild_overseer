import 'package:flutter/material.dart';

import '../../../../core/domain/combat_snapshot.dart';
import '../battle_palette.dart';

/// One combatant's live state: health, who it is hitting, and what its rotation
/// has ready. The arena shows the fight; this shows why it is going that way.
class UnitCard extends StatelessWidget {
  const UnitCard({required this.unit, this.compact = false, super.key});

  final UnitSnapshot unit;

  /// Drops the target line and cooldown chips, for narrow layouts.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final Color factionColor = BattlePalette.faction(unit.faction);
    final Color roleColor = BattlePalette.role(unit.role);
    final bool alive = unit.isAlive;

    return Opacity(
      opacity: alive ? 1 : 0.45,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        decoration: BoxDecoration(
          color: BattlePalette.panel,
          border: Border(
            left: BorderSide(color: roleColor, width: 3),
            top: const BorderSide(color: BattlePalette.gridLine),
            right: const BorderSide(color: BattlePalette.gridLine),
            bottom: const BorderSide(color: BattlePalette.gridLine),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _header(context, roleColor, alive),
            const SizedBox(height: 6),
            _healthBar(factionColor),
            if (!compact) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                alive
                    ? '-> ${unit.targetName ?? 'no target'}   ·   ${unit.priority.label}'
                    : 'down',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  color: BattlePalette.textMuted,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: <Widget>[
                  for (final SkillSnapshot skill in unit.skills)
                    _SkillChip(skill: skill, accent: roleColor),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, Color roleColor, bool alive) => Row(
        children: <Widget>[
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            color: roleColor,
            child: Text(
              unit.role.glyph,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0B0D14),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              unit.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: BattlePalette.textPrimary,
                decoration: alive ? null : TextDecoration.lineThrough,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${unit.health.toStringAsFixed(0)}/${unit.maxHealth.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 10,
              color: BattlePalette.textMuted,
            ),
          ),
        ],
      );

  Widget _healthBar(Color factionColor) => Stack(
        children: <Widget>[
          Container(height: 6, color: const Color(0xFF0B0D14)),
          FractionallySizedBox(
            widthFactor: unit.healthFraction,
            child: Container(height: 6, color: factionColor),
          ),
        ],
      );
}

/// A skill with its cooldown drawn as a fill that refills left to right.
class _SkillChip extends StatelessWidget {
  const _SkillChip({required this.skill, required this.accent});

  final SkillSnapshot skill;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final bool ready = skill.isReady;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: ready ? accent : BattlePalette.gridLine,
        ),
      ),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: skill.progress,
              child: Container(color: accent.withValues(alpha: 0.22)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            child: Text(
              skill.name,
              style: TextStyle(
                fontSize: 10,
                color: ready
                    ? BattlePalette.textPrimary
                    : BattlePalette.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
