import 'package:flutter/material.dart';

import '../../../battle/domain/skill.dart';
import '../../../battle/domain/unit_blueprint.dart';
import '../../../battle/view/battle_palette.dart';
import 'role_glyph.dart';

/// One recruitable unit, as a card.
///
/// The bench entry and the thing that floats under the pointer while it is
/// being dragged are the same card, so what the player picked up is plainly
/// what they are carrying.
class BlueprintCard extends StatelessWidget {
  const BlueprintCard({
    required this.blueprint,
    this.held = false,
    this.placed = false,
    this.onTap,
    this.onEditSkills,
    super.key,
  });

  final UnitBlueprint blueprint;

  /// Picked up and waiting for a slot: the select-and-place flow's cursor.
  final bool held;

  /// Already standing in the formation. Still tappable — that is how a placed
  /// unit is picked back up.
  final bool placed;

  final VoidCallback? onTap;

  /// Opens the skill picker for this unit. Null on a card that is only being
  /// looked at — the one floating under a drag, for instance.
  final VoidCallback? onEditSkills;

  @override
  Widget build(BuildContext context) {
    final Color roleColor = BattlePalette.role(blueprint.role);
    final Color edge = held ? BattlePalette.ally : BattlePalette.gridLine;

    return Semantics(
      button: onTap != null,
      selected: held,
      label: blueprint.name,
      child: InkWell(
        onTap: onTap,
        child: Opacity(
          opacity: placed ? 0.5 : 1,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: held
                  ? BattlePalette.ally.withValues(alpha: 0.12)
                  : BattlePalette.panel,
              border: Border(
                left: BorderSide(color: roleColor, width: 3),
                top: BorderSide(color: edge),
                right: BorderSide(color: edge),
                bottom: BorderSide(color: edge),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _header(roleColor),
                const SizedBox(height: 6),
                Text(
                  '${blueprint.role.label}  ·  ${blueprint.priority.label}',
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
                    for (final SkillDefinition skill in blueprint.skills)
                      _SkillTag(name: skill.name, accent: roleColor),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(Color roleColor) => Row(
        children: <Widget>[
          RoleGlyph(role: blueprint.role),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              blueprint.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: BattlePalette.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            blueprint.maxHealth.toStringAsFixed(0),
            style: const TextStyle(
              fontSize: 10,
              color: BattlePalette.textMuted,
            ),
          ),
          if (onEditSkills != null)
            IconButton(
              onPressed: onEditSkills,
              visualDensity: VisualDensity.compact,
              iconSize: 14,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              padding: EdgeInsets.zero,
              tooltip: 'Skills for ${blueprint.name}',
              icon: const Icon(Icons.bolt, color: BattlePalette.textMuted),
            ),
        ],
      );
}

/// A skill the unit brings: what it was authored with until the player opens
/// the picker, and what they chose afterwards.
class _SkillTag extends StatelessWidget {
  const _SkillTag({required this.name, required this.accent});

  final String name;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(border: Border.all(color: accent)),
        child: Text(
          name,
          style: const TextStyle(
            fontSize: 10,
            color: BattlePalette.textPrimary,
          ),
        ),
      );
}
